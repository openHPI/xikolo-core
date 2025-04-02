import { merge } from 'webpack-merge';

import CompressionPlugin from 'compression-webpack-plugin';
import TerserPlugin from 'terser-webpack-plugin';

import common from './webpack.common.mjs';

export default async (settings) => {
  const base = await common({ ...settings });

  return merge(base, {
    mode: 'production',
    devtool: 'source-map',

    optimization: {
      minimizer: [
        new TerserPlugin({
          extractComments: false,
          parallel: true,
        }),
      ],
    },

    plugins: [
      new CompressionPlugin({
        test: /\.(js|css|html|svg)$/,
        compressionOptions: { numiterations: 15 },
      }),
    ],
  });
};
