/* eslint-disable import/no-extraneous-dependencies */
//
import { join } from 'path';

import MiniCssExtractPlugin from 'mini-css-extract-plugin';
import webpack from 'webpack';
import WebpackAssetsManifest from 'webpack-assets-manifest';
import { BundleAnalyzerPlugin } from 'webpack-bundle-analyzer';

import makeEntries from './entries.mjs';
import makeRules from './loaders.mjs';

export default async (settings) => {
  const { brand, mode, publicPath, root } = settings;

  const entry = await makeEntries(settings);
  const rules = await makeRules(settings);

  const brandPath = join(root, 'brand', brand, 'assets');
  const defaultPath = join(root, 'app', 'assets');

  // eslint-disable-next-line no-console
  console.log(`==> Building ${brand}-${mode}...`);

  return {
    context: root,
    entry,

    output: {
      path: join(root, 'public', 'assets', 'webpack'),
      filename: '[name].[contenthash].js',
      publicPath,
      assetModuleFilename: '[name][hash][ext][query]',
    },

    resolve: {
      // We prefer to load more "modern" code, e.g. ES6+, because we target
      // modern browsers and transpile the code to specifically target them
      // anyway. It also produces much more optimized code if packages provide
      // more modern JS.
      mainFields: [
        // Packages shipping higher level code then module
        'es2017',
        'es2015',
        'esm2015',
        'fesm2015',

        // ES6 modules but ES5 otherwise
        'module',
        'jsnext:main',

        // standard fields
        'browser',
        'main',
      ],
      modules: [brandPath, defaultPath, join(root, 'node_modules')],
      extensions: ['.ts', '.js', '.mjs', '.sass', '.scss', '.css'],
    },

    module: {
      rules,
    },

    externals: {
      // Use legacy jquery from sprockets bundle <- DO NOT USE AT ALL
      jquery: 'jQuery',
    },

    plugins: [
      // Inject __BRAND__ and __MODE__ magic variables. They allow for
      // conditional code, e.g. print debug messages when not building in
      // production mode. Try to avoid using them, especially __BRAND__, unless
      // you are aware of the consequences.
      new webpack.DefinePlugin({
        __BRAND__: JSON.stringify(brand),
        __MODE__: JSON.stringify(mode),
      }),

      // Extract CSS into CSS files instead of JS bundles.
      new MiniCssExtractPlugin({
        filename: '[name].[contenthash].css',
      }),

      // Generate a manifest JSON file.
      //
      // This file is used by Rails to generate correct script and stylesheet
      // tags. It basically maps a symbolic name (app.js) to the compiled and
      // hashed asset file (app-46e6ef3.js) and some additional info such as SRI
      // hashes.
      new WebpackAssetsManifest({
        output: `.manifest.${brand}.json`,
        integrity: true,
        integrityHashes: ['sha384'],
        writeToDisk: true,
        contextRelativeKeys: true,
        publicPath,
        // Ignore a source maps and compressed files.
        customize(e) {
          // Skip source maps
          if (e.key.endsWith('.map') || e.key.endsWith('.gz')) {
            return false;
          }

          return e;
        },
      }),

      // Emit bundle statics to be used with webpack-bundle-analyzer cli.
      // Example:
      //     yarn run webpack-bundle-analyzer public/assets/webpack/.stats.xikolo.json
      new BundleAnalyzerPlugin({
        analyzerMode: 'disable',
        generateStatsFile: true,
        statsFilename: `.stats.${brand}.json`,
      }),
    ],
    optimization: {
      // Always do tree shaking to avoid issues in production only and to be
      // able to analyze module usage while in development environment.
      concatenateModules: true,

      // Use deterministic module IDs to avoid changes to *all* bundles just
      // because e.g. the load order changed.
      moduleIds: 'deterministic',

      // Emit a single runtime chunk: As we use multiple bundles on the same
      // page we want a single runtime chunk to be loaded first, instead of
      // having one runtime embedded in each bundle.
      runtimeChunk: 'single',
    },
  };
};
