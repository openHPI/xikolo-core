# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.tap do |config|
  # Version of your assets, change this if you want to expire all your
  # assets.
  config.assets.version = '1.0'

  # Use brand specific manifest for sprockets because assets can be
  # overridden in the brand specific path added further down
  config.assets.manifest = Rails.root.join("public/assets/.sprockets.#{Xikolo.brand}.json")

  # Add additional assets to the asset load path.

  # Add brand specific path *before* the regular `app/assets` directory
  # to be able to override specific assets such as `logo.png`
  config.paths['app/assets'] = [
    "brand/#{Xikolo.brand}/assets",
    'app/assets',
  ]

  config.assets.precompile << "foundation_#{Xikolo.brand}.css"
end
