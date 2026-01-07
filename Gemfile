# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.4.0'

# Rails
gem 'rails', '~> 7.2.0'
gem 'turbo-rails'

gem 'base64'
gem 'bigdecimal'
gem 'csv'
gem 'drb'
gem 'json'
gem 'mutex_m'
gem 'ostruct'
gem 'syslog'

# Database
gem 'activerecord-postgres_enum', '~> 2.0'
gem 'acts_as_list'
gem 'awesome_nested_set', '~> 3.4'
gem 'fx', '~> 0.9.0'
gem 'groupdate', '~> 6.0'
gem 'has_scope'
gem 'json-schema'
gem 'paper_trail', '~> 16.0'
gem 'pg', '~> 1.0'
gem 'scenic', '~> 1.5'

# Cache storage
gem 'redis', '~> 5.0'

# App servers
gem 'puma'
gem 'thruster'

# API & Messaging
gem 'api-responder'
gem 'grape', '~> 2.2', '< 2.3' # breaks deprecated API::V2
gem 'grape-entity'
gem 'msgr', '~> 1.5' # Connecting to RabbitMQ
gem 'oj'
gem 'rack', '~> 3.1.0'
gem 'rack-attack'
gem 'rack-cors', '~> 3.0'
gem 'restify', '~> 2.0'

gem 'decorate-responder', '~> 2.0'
gem 'draper'
gem 'mechanize'
gem 'paginate-responder', '~> 2.0'
gem 'rails-rfc6570', '~> 3.0'
gem 'responders'
gem 'will_paginate'

gem 'workflow', '~> 3.0'
gem 'workflow-activerecord', '>= 4.1', '< 6.1'

# Views (Template engines & components)
gem 'gon', '~> 6.4'
gem 'jbuilder'
gem 'lookbook', '~> 2.0'
gem 'rails-i18n', '~> 7.0'
gem 'slim'
gem 'view_component', '~> 3.0'

# Helper
gem 'addressable'
gem 'browser', '~> 6.0'
gem 'dry-validation'
gem 'http_accept_language'
gem 'idn-ruby', '~> 0.1.0' # Used by Addressable when available (for better performance)
gem 'imgproxy'
gem 'meta-tags', '~> 2.0', require: 'meta_tags'
gem 'rack-link_headers', '~> 2.2'
gem 'rubyzip', '~> 2.4.0', require: 'zip'
gem 'sanitize'
gem 'simple_form', '~> 5.0'
gem 'truncato', '~> 0.7.13'
gem 'uuid4', '~> 1.4'
gem 'xui-form', path: 'gems/xui-form'

gem 'icalendar'

gem 'countries', '~> 8.0' # ISO country codes
gem 'country_select', '~> 11.0'
gem 'i18n_data'
gem 'maxminddb', '~> 0.1' # Location tracking

# Xikolo service gems
gem 'acfs', '~> 2.0', '>= 2.0.0'
gem 'xikolo-account',         '~> 8.0',   path: 'clients/xikolo-account'
gem 'xikolo-course',          '~> 12.0',  path: 'clients/xikolo-course'
gem 'xikolo-pinboard',        '~> 5.0',   path: 'clients/xikolo-pinboard'
gem 'xikolo-quiz',            '~> 5.0',   path: 'clients/xikolo-quiz'
gem 'xikolo-submission',      '~> 100.0', path: 'clients/xikolo-submission'

# Xikolo services as an engine
gem 'account_service', path: 'engines/account_service'
gem 'course_service', path: 'engines/course_service'
gem 'news_service', path: 'engines/news_service'
gem 'notification_service', path: 'engines/notification_service'
gem 'pinboard_service', path: 'engines/pinboard_service'
gem 'quiz_service', path: 'engines/quiz_service'
gem 'timeeffort_service', path: 'engines/timeeffort_service'

gem 'activejob-cancel'
gem 'delayed', '~> 1.0'
gem 'sidekiq-cron', '~> 2.0'
gem 'xikolo-common', path: './gems/xikolo-common'
gem 'xikolo-config', path: './gems/xikolo-config'
gem 'xikolo-s3', path: './gems/xikolo-s3'
gem 'xikolo-sidekiq', path: './gems/xikolo-sidekiq'

# Authentication
gem 'bcrypt', '~> 3.1'
gem 'oauth2'
gem 'omniauth_openid_connect', '~> 0.4'
gem 'omniauth-saml', '~> 2.1'
gem 'paseto' # for token encryption
gem 'rexml', '>= 3.2.1' # https://github.com/onelogin/ruby-saml/issues/516
gem 'ruby-saml', '~> 1.14'

# reCAPTCHA
gem 'recaptcha', '5.19.0'

# HTML Emails
gem 'inky-rb', require: 'inky'
gem 'premailer-rails'

# LTI integration
# Version 2 implements LTI 2.0, which is deprecated. Hence, we stay with version 1.
gem 'ims-lti', '~> 1.2', '< 2.0.0'

# Video support
gem 'kaltura-client'
gem 'm3u8', '~> 0.8.2'
gem 'streamio-ffmpeg'
gem 'webvtt-ruby', '~> 0.4.0'

# Markdown support
gem 'redcarpet'

# PDF
gem 'arabic-letter-connector'
gem 'matrix', '~> 0.4' # required by prawn on Ruby 3.1+
gem 'prawn', '~> 2.0'
gem 'prawn-qrcode'
gem 'prawn-svg'
gem 'prawn-table'
gem 'prawn-templates', '~> 0.1.0'

# Monitoring
gem 'scientist', '~> 1.0'
gem 'vernier'                   # vernier must be required before Sentry
gem 'sentry-rails', '~> 5.26.0' # rubocop:disable Bundler/OrderedGems
gem 'sentry-ruby', '~> 5.26.0'
gem 'sentry-sidekiq', '~> 5.26.0'
gem 'telegraf', '~> 3.0'

gem 'rsvg2', '~> 4.2.9'
gem 'svg-graph', '~> 2.1', require: 'svggraph'

# Open Badges
gem 'chunky_png'
gem 'jwt', '~> 2.0' # 3.0 requires a longer RSA key length

# Assets
gem 'rails-assets-manifest', '~> 3.0', '>= 3.0.1'
gem 'sprockets', '~> 4.2'
gem 'sprockets-rails', '~> 3.5'

group :assets do
  gem 'dartsass-sprockets'
  gem 'i18n-js', '~> 4.2', '>= 4.2.3'
  gem 'terser', '~> 1.1'
  gem 'tilt', '~> 2.0'
end

group :development do
  gem 'bootsnap', require: false
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'dotenv'

  gem 'letter_opener'
  gem 'listen', '~> 3.9.0'
  gem 'rubocop', '~> 1.75.0'
  gem 'rubocop-capybara', '~> 2.22.0'
  gem 'rubocop-factory_bot', '~> 2.27.0'
  gem 'rubocop-performance', '~> 1.25.0'
  gem 'rubocop-rails', '~> 2.31.0'
  gem 'rubocop-rspec', '~> 3.6.0'
  gem 'rubocop-rspec_rails', '~> 2.31.0'
  gem 'slim_lint'
end

group :development, :integration do
  gem 'better_errors', require: !ENV.key?('CI')
  gem 'binding_of_caller', require: !ENV.key?('CI')
end

group :test do
  gem 'accept_values_for'
  gem 'capybara', '~> 3.36'
  gem 'factory_bot_rails', '~> 6.0'
  gem 'json_spec'
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver', '~> 4.11'
  gem 'timecop'
  gem 'uuidtools'
  gem 'webmock'
  gem 'webrick'

  gem 'rspec', '~> 3.10'
  gem 'rspec-collection_matchers'
  gem 'rspec-github', '~> 3.0', require: false
  gem 'rspec-its'
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'rspec-rails', '~> 8.0'
end

group :test, :integration do
  gem 'database_cleaner', '~> 2.0'
  gem 'rack-remote'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
end

gem 'pkg-config', '= 1.6.2'
gem 'solid_queue', '~> 1.2'
