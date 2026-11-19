# frozen_string_literal: true

SimpleCov.start do
  skip 'bin/'
  skip 'db/'
  skip 'docs/'
  skip 'debian/'
  skip 'config/'
  skip 'scripts/'
  skip 'services/'
  skip 'spec/'

  skip 'config.ru'
  skip 'Gemfile'
  skip 'Procfile'
  skip 'Rakefile'

  group 'API', 'api'
  group 'Background Processing', ['app/consumers', 'app/jobs', 'app/workers']
  group 'Business Logic', ['app/handlers', 'app/models', 'app/operations']
  group 'Controllers', 'app/controllers'
  group 'Forms', ['app/forms', 'app/inputs']
  group 'Helpers', 'app/helpers'
  group 'Library', ['lib', 'app/lib']
  group 'UI', ['app/components', 'app/presenters', 'app/views']
end
