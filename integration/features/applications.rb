# frozen_string_literal: true

Server.base = ENV['SERVICES_DIR'] if ENV.key? 'SERVICES_DIR'

# When running integration tests, only start the services we need.
Server.required_roles << :integration if ENV.key?('GURKE')

##
# CONFIGURE ALL SERVICES
#
# This list teaches integration about all of our services, where their code can
# be found and what they need to run. To do so, we assign them "roles" which
# define which files need to be copied, which processes should be started when
# running integration tests, and more.
#
# List of roles:
# - rails: services running Ruby on Rails (for clearing Rails-specific caches)
# - srv: services with a HTTP server that needs to be discoverable by other services
# - db: services that have a database
# - msgr: services that consume RabbitMQ events using the Msgr library
# - sidekiq: services that run background workers using Sidekiq
# - config: services that need scenario-specific `Xikolo.config` values
# - assets: services where assets should be built
# - integration: services that need to be started when running integration tests

# This is important, web must come first!
Server.add :web,                name: 'web',
  roles: %i[rails db assets msgr delayed config integration main],
  subpath: '.'

Server.add :account,            name: 'account',
  roles: %i[rails db account srv config integration],
  subpath: 'services/account'
Server.add :collabspace,        name: 'collabspace',
  roles: %i[rails db srv msgr sidekiq integration],
  subpath: 'services/collabspace'
Server.add :course,             name: 'course',
  roles: %i[rails db srv msgr sidekiq config integration],
  subpath: 'services/course'
Server.add :grouping,           name: 'grouping',
  roles: %i[rails db srv],
  subpath: 'services/grouping'
Server.add :news,               name: 'news',
  roles: %i[rails db srv msgr sidekiq config integration],
  subpath: 'services/news'
Server.add :notification,       name: 'notification',
  roles: %i[rails db srv msgr sidekiq config integration],
  subpath: 'services/notification'
Server.add :pinboard,           name: 'pinboard',
  roles: %i[rails db srv msgr sidekiq config integration],
  subpath: 'services/pinboard'
Server.add :quiz,               name: 'quiz',
  roles: %i[rails db srv sidekiq config integration],
  subpath: 'services/quiz'
Server.add :timeeffort,         name: 'timeeffort',
  roles: %i[rails db srv msgr sidekiq],
  subpath: 'services/timeeffort'
