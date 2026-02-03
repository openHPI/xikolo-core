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
Server.add :web, name: 'web',
  roles: %i[rails db assets msgr delayed config integration main srv sidekiq],
  subpath: '.'

Server.add_engine :account,
  mount_path: 'account_service'
Server.add_engine :course,
  mount_path: 'course_service'
Server.add_engine :news,
  mount_path: 'news_service'
Server.add_engine :notification,
  mount_path: 'notification_service'
Server.add_engine :pinboard,
  mount_path: 'pinboard_service'
Server.add_engine :quiz,
  mount_path: 'quiz_service'
Server.add_engine :timeeffort,
  mount_path: 'timeeffort_service'
