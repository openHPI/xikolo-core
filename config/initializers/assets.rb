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

  # Add additional assets to the asset load path.

  # Add brand specific path *before* the regular `app/assets` directory to be
  # able to override specific assets such as `logo.png`
  config.paths['app/assets'] = [
    "brand/#{Xikolo.brand}/assets",
    'app/assets',
  ]

  # As a prerequisite for migrating to webpack, we temporarily import certain node modules into sprockets
  config.assets.paths << Rails.root.join('node_modules/bootstrap-sass/assets/javascripts')

  # Override the default assets matcher since that matches, for example,
  # all TypeScript files too. Instead, we load only an allowed list of
  # image file extensions by default and include files from `./brand`.
  config.assets.precompile = []
  config.assets.precompile << lambda do |logical_path, filename|
    (
      filename.start_with?(Rails.root.join('app/assets').to_s) ||
      filename.start_with?(Rails.root.join('brand').to_s)
    ) && logical_path =~ /\.(gif|ico|jpe?g|png|svg)$/
  end

  # Load default application.(js|css)
  config.assets.precompile << %r{(?:/|\\|\A)application\.(css|js)$}

  # Precompile additional assets.
  config.assets.precompile += %w[admin-legacy.js]
  config.assets.precompile += %w[course-admin.js]

  config.assets.precompile += %w[charts.js]
  config.assets.precompile += %w[peer_assessment/train_samples.js]

  ## m.e.i.n.e.l
  config.assets.precompile += %w[m.e.i.n.e.l.js]

  # Expensive libraries
  config.assets.precompile += %w[moment.js]
end
