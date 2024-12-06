# frozen_string_literal: true

SimpleCov.start do
  add_filter 'bin/'
  add_filter 'db/'
  add_filter 'docs/'
  add_filter 'debian/'
  add_filter 'config/'
  add_filter 'scripts/'
  add_filter 'services/'
  add_filter 'spec/'

  add_filter 'config.ru'
  add_filter 'Gemfile'
  add_filter 'Procfile'
  add_filter 'Rakefile'

  add_group 'API', 'api'
  add_group 'Background Processing', ['app/consumers', 'app/jobs', 'app/workers']
  add_group 'Business Logic', ['app/handlers', 'app/models', 'app/operations']
  add_group 'Controllers', 'app/controllers'
  add_group 'Forms', ['app/forms', 'app/inputs']
  add_group 'Helpers', 'app/helpers'
  add_group 'Library', ['lib', 'app/lib']
  add_group 'UI', ['app/components', 'app/presenters', 'app/views']
end
