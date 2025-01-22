# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

def system_call(command)
  puts "Running '#{command}'..."
  unless system(command)
    raise "#{command} failed"
  end
end

Xikolo::Web::Application.load_tasks

namespace :ci do
  desc 'Setup service for CI'
  task setup: %w[assets:i18n:export db:drop:all db:create:all db:schema:load]

  begin
    require 'rspec/core/rake_task'
    desc 'Run specs for CI'
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.rspec_opts = '--tag ~gen:2'
    end
  rescue LoadError
    # noop
  end
end

namespace :api do
  desc 'Generate the documentation for the REST API'
  task docs: :environment do
    Xikolo::API.make_docs!
  end
end

namespace :assets do
  task precompile: %w[assets:brand:check]

  namespace :brand do
    task check: :environment do
      # xikolo is the default brand and only relies on `app/assets/` (has no overrides in `brand/`)
      next if ENV['BRAND'] == 'xikolo'

      if ENV['BRAND'] && !Rails.root.join('brand', ENV['BRAND']).exist?
        raise <<~ERROR
          Brand directory `brand/#{ENV['BRAND']}' does not exist.
        ERROR
      end
    end
  end

  namespace :i18n do
    task export: :environment do
      require 'i18n-js'
      I18nJS.call(config_file: 'config/i18n.yml')
    end
  end
end

namespace :i18n do
  desc 'Find and list translation keys that do not exist in all locales'
  task missing_keys: :environment do
    def collect_keys(scope, translations)
      full_keys = []
      translations.to_a.each do |key, values|
        new_scope = scope.dup << key
        if values.is_a?(Hash)
          full_keys += collect_keys(new_scope, values)
        else
          full_keys << new_scope.join('.')
        end
      end
      full_keys
    end

    # Make sure we've loaded the translations
    I18n.backend.send(:init_translations)
    puts "#{I18n.available_locales.size} locale(s) available: #{I18n.available_locales.to_sentence}"

    # Get all keys from all locales
    all_keys = I18n.backend.send(:translations).collect do |_check_locale, translations|
      collect_keys([], translations).sort
    end.flatten.uniq
    puts "#{all_keys.size} #{all_keys.size == 1 ? 'unique key' : 'unique keys'} found."

    missing_keys = {}
    all_keys.each do |key|
      next if key == 'i18n.plural.rule'

      I18n.available_locales.each do |locale|
        I18n.locale = locale
        begin
          I18n.t(key, raise: true)
        rescue I18n::MissingInterpolationArgument
          # noop
        rescue I18n::MissingTranslationData
          if missing_keys[key]
            missing_keys[key] << locale
          else
            missing_keys[key] = [locale]
          end
        end
      end
    end

    puts "#{missing_keys.size} key(s) missing from:"
    missing_keys.keys.sort.each do |key|
      puts "'#{key}': Missing from #{missing_keys[key].join(', ')}"
    end
  end
end
