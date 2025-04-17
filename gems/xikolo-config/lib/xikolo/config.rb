# frozen_string_literal: true

require 'active_support/configurable'
require 'active_support/string_inquirer'
require 'addressable'
require 'erb'
require 'yaml'

module Xikolo
  include ActiveSupport::Configurable

  config_accessor :site, :brand, :base_url

  class Configuration < ActiveSupport::Configurable::Configuration
    def load_file(path)
      if (data = parse_file(path))
        merge(data)
      end
    end

    def parse_file(path)
      $stdout.puts "[xikolo.config] Load file: #{path}" if ENV['RAILS_ENV'] == 'production'
      YAML.safe_load(ERB.new(::File.read(path)).result)
    end

    def merge(opts)
      opts.each do |k, v|
        send :"#{k}=", v
      end

      compile_methods!
    end
  end

  class GlobalConfiguration < Configuration
    %w[site brand].each do |string_inquirer_option|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1 # rubocop:disable Style/DocumentDynamicEvalDefinition
        # StringInquirer the string argument
        def #{string_inquirer_option}=(name)
          self[:#{string_inquirer_option}] = ActiveSupport::StringInquirer.new name
        end
      RUBY_EVAL
    end

    def base_url=(value)
      self[:base_url] = ::Addressable::URI.parse(value)
    end
  end

  class << self
    def config
      @config ||= ::Xikolo::GlobalConfiguration.new
    end
  end

  module Config
    def self.add_config_location(filename)
      @locations ||= []
      @locations << filename
      Xikolo.config.load_file filename if ::File.exist? filename
    end

    def self.reload
      (@locations || []).each do |location|
        Xikolo.config.load_file location if ::File.exist? location
      end
    end

    require 'xikolo/config/railtie' if defined? Rails
  end
end

# Load default configuration
Xikolo::Config.add_config_location File.expand_path('config.yml', __dir__)
