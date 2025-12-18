# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.tap do |config|
  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Use brand specific manifest for sprockets because assets can be overridden
  # in the brand specific path added further down
  config.assets.manifest = Rails.root.join("public/assets/.sprockets.#{Xikolo.brand}.json")

  # Manifest from Webpack
  config.assets_manifest.path = "public/assets/webpack/.manifest.#{Xikolo.brand}.json"
  config.assets_manifest.passthrough = true

  # As a prerequisite for migrating to webpack, we temporarily import certain node modules into sprockets
  config.assets.paths << Rails.root.join('node_modules/bootstrap-sass/assets/javascripts')
end
