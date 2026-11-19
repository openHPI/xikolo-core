# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 4.0.0'

# Environment variables need to be loaded first for
# other gems to see them.
gem 'dotenv', groups: %i[development test]

# Rails
gem 'rails', '~> 8.1.0'
gem 'turbo-rails', '>= 0'

gem 'base64', '>= 0'
gem 'bigdecimal', '>= 0'
gem 'cgi', '>= 0'
gem 'csv', '>= 0'
gem 'drb', '>= 0'
gem 'json', '>= 0'
gem 'mutex_m', '>= 0'
gem 'ostruct', '>= 0'
gem 'syslog', '>= 0'
gem 'tsort', '>= 0'

# Database
gem 'acts_as_list', '>= 0'
gem 'awesome_nested_set', '>= 0'
gem 'fx', '>= 0'
gem 'groupdate', '>= 0'
gem 'has_scope', '>= 0'
gem 'json-schema', '>= 0'
gem 'paper_trail', '>= 0'
gem 'pg', '>= 0'
gem 'scenic', '>= 0'
gem 'strong_migrations'

# Cache storage
gem 'connection_pool', '>= 0'
gem 'redis', '~> 5.0'

# App servers
gem 'puma', '>= 0'
gem 'thruster', '>= 0'

# API & Messaging
gem 'api-responder', '>= 0'
gem 'aws-sdk-s3', require: false
gem 'oj', '>= 0'
gem 'rack', '>= 0'
gem 'rack-attack', '>= 0'
gem 'rack-cors', '>= 0'
gem 'restify', '>= 0'

gem 'decorate-responder', '>= 0'
gem 'draper', '>= 0'
gem 'paginate-responder', '>= 0'
gem 'rails-rfc6570', '>= 0'
gem 'responders', '>= 0'
gem 'will_paginate', '>= 0'

gem 'google-apis-drive_v3', '>= 0'
gem 'google-apis-sheets_v4', '>= 0'
gem 'googleauth', '>= 0'
gem 'workflow', '>= 0'
gem 'workflow-activerecord', '>= 0'

# Views (Template engines & components)
gem 'lookbook', '>= 0'
gem 'rails-i18n', '>= 0'
gem 'slim', '>= 0'
gem 'view_component', '>= 0'

# Helper
gem 'addressable', '>= 0'
gem 'browser', '>= 0'
gem 'http_accept_language', '>= 0'
gem 'imgproxy', '>= 0'
gem 'meta-tags', '>= 0', require: 'meta_tags'
gem 'rack-link_headers', '>= 0'
gem 'rubyzip', '>= 0', require: 'zip'
gem 'sanitize', '>= 0'
gem 'simple_form', '>= 0'
gem 'truncato', '>= 0'
gem 'uuid4', '>= 0'
gem 'xui-form', '>= 0', path: 'gems/xui-form'

gem 'icalendar', '>= 0'

gem 'countries', '>= 0' # ISO country codes
gem 'country_select', '>= 0'
gem 'i18n_data', '>= 0'
gem 'maxminddb', '>= 0' # Location tracking

# Xikolo service gems
gem 'acfs', '>= 0'
gem 'xikolo-account', path: 'clients/xikolo-account'
gem 'xikolo-course', path: 'clients/xikolo-course'
gem 'xikolo-pinboard', path: 'clients/xikolo-pinboard'
gem 'xikolo-quiz', path: 'clients/xikolo-quiz'
gem 'xikolo-submission', path: 'clients/xikolo-submission'

# Xikolo services as an engine
gem 'account_service', path: 'engines/account_service'
gem 'course_service', path: 'engines/course_service'
gem 'news_service', path: 'engines/news_service'
gem 'notification_service', path: 'engines/notification_service'
gem 'pinboard_service', path: 'engines/pinboard_service'
gem 'quiz_service', path: 'engines/quiz_service'

gem 'xikolo-common', path: './gems/xikolo-common'
gem 'xikolo-config', path: './gems/xikolo-config'
gem 'xikolo-s3', path: './gems/xikolo-s3'

# Authentication
gem 'bcrypt', '>= 0'
gem 'oauth2', '>= 0'
gem 'omniauth_openid_connect', '>= 0'
gem 'omniauth-saml', '>= 0'
gem 'rexml', '>= 0'
gem 'ruby-saml', '>= 0'

# reCAPTCHA
gem 'recaptcha', '>= 0'

# HTML Emails
gem 'inky-rb', '>= 0', require: 'inky'
gem 'premailer-rails', '>= 0'

# LTI integration
# Version 2 implements LTI 2.0, which is deprecated. Hence, we stay with version 1.
gem 'ims-lti', '~> 1.2', '< 2.0.0'

# Video support
gem 'm3u8', '>= 0'
gem 'streamio-ffmpeg', '>= 0'
gem 'webvtt-ruby', '>= 0'

# Validation
gem 'active_storage_validations'

# Markdown support
gem 'redcarpet', '>= 0'

# PDF
gem 'arabic-letter-connector', '>= 0'
gem 'matrix', '>= 0'
gem 'prawn', '>= 0'
gem 'prawn-qrcode', '>= 0'
gem 'prawn-svg', '>= 0'
gem 'prawn-table', '>= 0'
gem 'prawn-templates', '>= 0'

# Monitoring
gem 'mission_control-jobs', '>= 0'
gem 'vernier', '>= 0'      # vernier must be required before Sentry
gem 'sentry-rails', '>= 0' # rubocop:disable Bundler/OrderedGems
gem 'sentry-ruby', '>= 0'
gem 'telegraf', '>= 0'

gem 'image_processing', '>= 0'
gem 'ruby-vips', '>= 0'
gem 'svg-graph', '>= 0', require: 'svggraph'

# Assets
gem 'cssbundling-rails', '>= 0'
gem 'jsbundling-rails', '>= 0'
gem 'propshaft', '>= 0'

group :assets do
  gem 'i18n-js', '>= 0'
end

gem 'bootsnap', '>= 0', require: false

group :production do
  gem 'coverband', '>= 0'
end

group :development, :test do
  gem 'debug', '>= 0', platforms: %i[mri windows]

  gem 'letter_opener', '>= 0'
  gem 'listen', '>= 0'
  gem 'rubocop', '>= 0'
  gem 'rubocop-capybara', '>= 0'
  gem 'rubocop-factory_bot', '>= 0'
  gem 'rubocop-performance', '>= 0'
  gem 'rubocop-rails', '>= 0'
  gem 'rubocop-rspec', '>= 0'
  gem 'rubocop-rspec_rails', '>= 0'
  gem 'slim_lint', '>= 0'
end

group :development do
  gem 'hotwire-livereload', '>= 0' unless !!ENV['DISABLE_LIVE_RELOAD']
  gem 'web-console', '>= 0'
end

group :test do
  gem 'accept_values_for', '>= 0'
  gem 'capybara', '>= 0'
  gem 'factory_bot_rails', '>= 0'
  gem 'json_spec', '>= 0'
  gem 'parallel_tests', '>= 0'
  gem 'pdf-inspector', '>= 0', require: 'pdf/inspector'
  gem 'rails-controller-testing', '>= 0'
  gem 'selenium-webdriver', '>= 0'
  gem 'simplecov', '>= 0', require: false
  gem 'simplecov-cobertura', '>= 0', require: false
  gem 'timecop', '>= 0'
  gem 'uuidtools', '>= 0'
  gem 'webmock', '>= 0'
  gem 'webrick', '>= 0'

  gem 'rspec', '>= 0'
  gem 'rspec-collection_matchers', '>= 0'
  gem 'rspec-github', '>= 0', require: false
  gem 'rspec-its', '>= 0'
  gem 'rspec_junit_formatter', '>= 0', require: false
  gem 'rspec-rails', '>= 0'
  gem 'rspec-rebound', '>= 0'
end

gem 'solid_queue', '>= 0'

gem 'maintenance_tasks', '~> 2.17'
