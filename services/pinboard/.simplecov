# frozen_string_literal: true

SimpleCov.start do
  add_filter 'bin/'
  add_filter 'db/'
  add_filter 'config/'
  add_filter 'spec/'

  add_filter 'config.ru'
  add_filter 'Gemfile'
  add_filter 'Procfile'
  add_filter 'Rakefile'

  add_group 'API', ['app/controllers', 'app/decorators']
  add_group 'Background Processing', ['app/consumers', 'app/workers']
  add_group 'Business Logic', ['app/models', 'app/operations']
  add_group 'Helpers', 'app/helpers'
end
