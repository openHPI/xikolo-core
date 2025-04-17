# frozen_string_literal: true

require 'active_support/concern'

module Xikolo
  module Common
    # Load configurations from `/local/config` too, since that directory
    # is used by Nomad to inject templates, and we will not need to bind
    # mount all config additionally into `/app/config`.
    module Nomad
      extend ActiveSupport::Concern

      included do
        prepend LocalConfigFor

        unless Rails.env.local?
          config.paths['config'].unshift '/local/config'
          config.paths['config/database'].unshift '/local/config/database.yml'
          config.paths['config/secrets'] << '/local/config'
        end
      end

      module LocalConfigFor
        def lookup_config_for(name)
          return name if name.is_a?(Pathname)

          files = paths['config'].existent.map {|path| Pathname.new(path).join("#{name}.yml") }
          if (file = files.find(&:file?))
            $stdout.puts "Loading config for #{name}: #{file}" if Rails.env.production?
            return file
          end

          raise "Could not load configuration. No such files - #{files}"
        end

        def config_for(name, env: Rails.env)
          yaml = lookup_config_for(name)

          if yaml.exist?
            require 'erb'
            all_configs = ActiveSupport::ConfigurationFile.parse(yaml).deep_symbolize_keys
            config = all_configs[env.to_sym]
            shared = all_configs[:shared]

            if shared
              config = {} if config.nil? && shared.is_a?(Hash)
              if config.is_a?(Hash) && shared.is_a?(Hash)
                config = shared.deep_merge(config)
              elsif config.nil?
                config = shared
              end
            end

            if config.is_a?(Hash)
              config = ActiveSupport::OrderedOptions.new.update(config)
            end

            config
          else
            raise "Could not load configuration. No such file - #{yaml}"
          end
        end
      end
    end
  end
end
