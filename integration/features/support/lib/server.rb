# frozen_string_literal: true

require 'multi_process'
require 'pathname'
require 'active_support'
require 'active_support/core_ext'
require 'restify'
require 'mkmf'
require 'net/http'
require 'aws-sdk-s3'

ChildProcess.posix_spawn = true

class Server < MultiProcess::Process
  include MultiProcess::Process::Rails

  attr_reader :id, :roles, :repo, :address

  def initialize(id, opts = {})
    @id    = id
    @name  = opts[:name]
    @roles = Array(opts[:roles]).compact
    @repo  = opts[:repo] || "xikolo/#{@name}"
    @port  = opts[:port]

    @address = '127.0.0.1'

    self.server = 'puma'

    dir = ::File.join(Server.base, opts.fetch(:subpath))
    env = {
      'RAILS_ENV' => 'integration',
      'GURKE' => 'true',
    }

    super(dir:, env:, title: id.to_s)
  end

  def server_command
    cmd = %w[ruby]
    cmd << '-S' << 'bundle' << 'exec' << 'puma'
    cmd << '--workers' << '0' << '--threads' << '3'
    cmd << '--bind' << "tcp://#{address}:#{port}"
    cmd
  end

  def bundle(task, *cmd)
    opts = cmd.last.is_a?(Hash) ? cmd.pop : {}

    args = []
    opts.slice(:path, :without).compact.each do |key, value|
      args << "--#{key}" << value.to_s
    end

    process 'ruby', '-S', 'bundle', task.to_s, *cmd, *args, opts
  end

  def process(*command)
    opts = command.last.is_a?(Hash) ? command.pop : {}
    opts = opts.merge(dir:, title: id)
    command.map!(&:to_s)

    opts[:env] ||= {}
    opts[:env]['BUNDLE_PATH'] = ENV['BUNDLE_PATH'] if ENV.key?('BUNDLE_PATH')

    MultiProcess::Process.new(*command, opts)
  end

  def file(*path)
    dir.join(*path.flatten)
  end

  def dir
    ::Pathname.new super
  end

  def available?
    if @last_avil_time.nil? || (Time.current - @last_avil_time) > 5
      @last_avil_time = Time.current
      receiver.message self, :sys, "Waiting for server on #{port}..."
    end

    super
  end

  def url(string = '/')
    "http://#{address}:#{port}#{string}"
  end

  def api
    @restify ||= Restify.new(url).get.value! # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  class << self
    attr_writer :base

    def base
      @base ||= '..'
    end

    def required_roles
      @required_roles ||= []
    end

    def logger
      @logger ||= Logger.new sys: true, collapse: false
    end

    def group
      @group ||= MultiProcess::Group.new receiver: logger
    end

    def delayed_group
      @delayed_group ||= MultiProcess::Group.new receiver: logger
    end

    def sidekiq_group
      @sidekiq_group ||= MultiProcess::Group.new receiver: logger
    end

    def utils_group
      @utils_group ||= MultiProcess::Group.new receiver: logger
    end

    def util(key)
      utils_group.processes.find {|util| util.id == key }
    end

    def add(*args)
      opts = args.extract_options!

      # Ignore services that lack the required roles
      return if (required_roles - opts[:roles]).any?

      server = Server.new(*args, opts.merge(port: next_port))
      delayed_group << DelayedProcess.new(*args, opts) if server.roles.include? :delayed
      sidekiq_group << SidekiqProcess.new(*args, opts) if server.roles.include? :sidekiq
      group << server
    end

    def [](key)
      group.processes.find {|srv| srv.id == key }
    end

    def next_port
      @next_port ||= 8000 - 1
      @next_port += 1
    end

    def list(*roles)
      if roles.empty?
        group.processes
      else
        group.processes.select do |app|
          roles.all? {|role| app.roles.include? role }
        end
      end
    end

    def each(*roles, &)
      list(*roles).each(&)
    end

    def rake_log
      @rake_log ||= File.open('rake.log', 'w')
    end

    def exec(*roles, &)
      opts = roles.last.is_a?(Hash) ? roles.pop : {}
      unless opts.key? :receiver
        opts = opts.merge receiver: MultiProcess::Logger.new($stdout, $stderr,
          sys: opts.fetch(:sys, true))
      end
      opts = opts.merge partition: 2 if ENV['TEAMCITY_VERSION'] && !opts[:partition]

      timout = opts.delete(:timeout) || 240

      group = MultiProcess::Group.new(**opts)
      group << list(*roles).map(&).compact
      group.run!(delay: (opts[:delay] ? Float(opts[:delay]) : 0.5), timeout: timout)
    end

    def start
      if ENV['TEAMCITY_VERSION']
        group.start delay: 0.5
        delayed_group.start delay: 0.5
        sidekiq_group.start delay: 0.5
        group.available! timeout: 240
      else
        group.start delay: 0.1
        delayed_group.start delay: 0.1
        sidekiq_group.start delay: 0.1
        group.available! # default timeout
      end
    end

    def config_all
      $stdout.puts '(~)> Pre-init configuration...'
      $stdout.flush

      config_initializers
      config_services
      config_service_urls
      config_s3

      # Adjust simplecov coverage results from unit tests to have correct file names
      adjust_coverage_results if ENV['TEAMCITY_VERSION']
    end

    def config_initializers
      Server.each do |app|
        base = app.dir.join('config', 'initializers')
        base.mkpath

        Dir[base.join('integration*.rb')].each {|f| File.unlink f }
        FileUtils.ln_s Gurke.root.join('support/lib/initializers/integration.rb'), base
      end

      %i[config main msgr sidekiq].each do |type|
        Server.each(type) do |app|
          FileUtils.ln_s Gurke.root.join("support/lib/initializers/integration_#{type}.rb"),
            app.dir.join('config', 'initializers')
        end
      end
    end

    def config_services
      # A few services need special setup for integration tests
      %i[web account]
        .filter_map {|type| Server[type] }
        .each do |app|
          FileUtils.ln_s Gurke.root.join("support/lib/initializers/integration_#{app.id}.rb"),
            app.dir.join('config', 'initializers', "integration_x#{app.id}.rb")
        end
    end

    def config_service_urls
      Server.each do |app|
        File.write app.file('config/services.integration.yml'), YAML.dump(services_config)
      end
    end

    def config_s3
      conf = YAML.load_file(Gurke.root.join('support/lib/xikolo.yml').to_s)
      conf['domain'] = BASE_URI.host
      conf['domain'] += ":#{BASE_URI.port}" if BASE_URI.port
      conf['base_url'] = BASE_URI.to_s

      if ENV['S3_CONFIG_FILE']
        s3_config = YAML.safe_load_file(ENV['S3_CONFIG_FILE'])
        Xikolo.config['s3'] = s3_config['web']
        # already build resource object (the credentials might be
        # overwritten later on)
        Xikolo::S3.resource
      end

      # Create buckets with needed policies
      Minio.setup

      Server.each :config do |app|
        dest = app.file('config', 'xikolo.integration.yml')
        dest.unlink if dest.exist?
        if s3_config
          conf.delete('s3')
          conf['s3'] = s3_config[app.id.to_s] if s3_config.key? app.id.to_s
        end
        dest.write YAML.dump conf
      end
    end

    def adjust_coverage_results
      Server.each do |app|
        resultfile = app.file('coverage', '.resultset.json')
        next unless resultfile.exist?

        system 'sed',
          '--in-place',
          "--expression=s|/var/lib/teamcity-agent/work/[^/]*/|#{File.realpath(app.dir)}/|",
          app.file('coverage', '.resultset.json').to_s
      end
    end

    def start_all
      $stdout.puts '(~)> Starting utilies...'
      $stdout.flush

      # start helper processes like minio (for S3 API)
      utils_group.start
      utils_group.available!

      $stdout.puts '(~)> Utilities started.'
      $stdout.flush

      config_all

      $stdout.puts '(~)> Starting applications...'
      $stdout.flush

      Server.each do |app|
        Rack::Remote.add app.id.to_sym, url: "http://127.0.0.1:#{app.port}/__rack_remote_rpc__"
      end
      Server.start

      $stdout.puts '(~)> Applications started.'
      $stdout.flush
    end

    def stop_all
      processes = [utils_group, delayed_group, sidekiq_group].flat_map(&:processes)

      $stdout.puts '(~)> Stopping processes ...'
      Server.each(&:stop)
      processes.each(&:stop)

      Server.each do |app|
        Dir[app.dir.join('config/initializers/integration*.rb')].each {|f| File.unlink f }
      end

      $stdout.puts '(~)> Application stopped.'
      $stdout.flush
    end
  end

  class Logger < MultiProcess::Logger
    def initialize(*args)
      super

      @tests = {}
      @files = {}
    end

    def received(process, name, message)
      if (file = file_handle_for(process))
        file.puts "#{stream_symbol(name)} #{message.gsub(/\033.*?m/, '')}"
        file.flush
      end

      return if name == :out

      super
    end

    def stream_symbol(name)
      {sys: '$', out: '|', err: 'E'}[name] || '?'
    end

    def file_handle_for(process)
      @files[process] ||= begin
        FileUtils.mkdir_p 'log'
        File.open "log/#{process.title}.log", 'w'
      end
    end
  end
end

class DelayedProcess < Server
  def server_command
    cmd = %w[ruby]
    cmd << '-S' << 'bundle' << 'exec' << 'rake' << 'delayed:work'
    cmd
  end
end

class SidekiqProcess < Server
  def server_command
    cmd = %w[ruby]
    cmd << '-S' << 'bundle' << 'exec' << 'sidekiq'
    cmd << '--verbose'
    cmd << '--env' << 'integration'
    cmd
  end
end
