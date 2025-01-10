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

  # Load generated i18n-js files containing the exported locale strings. These
  # files are created when running `rake i18n:js:export`, which is also part
  # of `rake assets:precompile`.
  config.assets.paths << Rails.root.join("tmp/cache/#{Xikolo.brand}")

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in the app/assets
  # folder are already added.

  # Lazy load all loose assets from brands just like Rails already does for
  # assets from `app/assets`, such as images, fonts, etc. (everything not JS or
  # CSS)
  config.assets.precompile << lambda do |logical_path, filename|
    filename.start_with?(Rails.root.join('brand').to_s) &&
      ['.js', '.css', ''].exclude?(File.extname(logical_path))
  end

  config.assets.precompile += %w[admin-legacy.js]
  config.assets.precompile += %w[course-admin.js]

  config.assets.precompile += %w[charts.js]
  config.assets.precompile += %w[peer_assessment/train_samples.js]

  # Localizations
  config.assets.precompile += %w[xikolo-locale-*.js]

  ## m.e.i.n.e.l
  config.assets.precompile += %w[m.e.i.n.e.l.js]

  # Expensive libraries
  config.assets.precompile += %w[moment.js]
end
