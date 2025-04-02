/* global process */

import { BundleAnalyzerPlugin } from 'webpack-bundle-analyzer';
import { merge } from 'webpack-merge';

import common from './webpack.common.mjs';

export default async (settings) => {
  const { brand } = settings;
  let { publicPath } = settings;

  // When running the development server we set this to emit full URLs in the
  // manifest JSON file. Rails does not care for that and will simply create
  // script and link tags with these full URLs.
  //
  // Therefore assets are directly loaded from the webpack-dev-server process
  // including its feature to hot-reload the page on changes.
  if (settings.devServer) {
    publicPath = 'http://localhost:3030/assets/webpack/';
  }

  const base = await common({ ...settings, publicPath });

  return merge(base, {
    mode: 'development',
    devtool: 'inline-source-map',

    stats: {
      errorDetails: true,
    },

    output: {
      pathinfo: true,
    },

    devServer: {
      allowedHosts: ['.localhost', 'localhost'],
      compress: true,
      headers: { 'Access-Control-Allow-Origin': '*' },
      host: 'localhost',
      port: 3030,
      client: {
        overlay: {
          warnings: false,
          errors: true,
        },
      },
      proxy: [{ context: ['/'], target: 'http://localhost:3000' }],
      static: {
        publicPath,
        watch: { ignored: /node_modules/ },
      },
    },

    plugins: [
      new BundleAnalyzerPlugin({
        // The analyzerMode mode is not support when running as
        // webpack-dev-server because the plugin cannot access the
        // written bundle files (which are not written at all when
        // running as a dev server).
        analyzerMode: process.env.WEBPACK_SERVE ? 'disable' : 'static',
        openAnalyzer: false,
        reportFilename: `report.${brand}.html`,
      }),
    ],
  });
};
