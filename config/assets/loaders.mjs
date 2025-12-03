import Extract from 'mini-css-extract-plugin';

import cssnano from 'cssnano';
import postcssEnv from 'postcss-preset-env';
import ImageMinimizerPlugin from 'image-minimizer-webpack-plugin';

export default async () => {
  // The image loader optimizes images before emitting
  // them into the bundle.
  const image = {
    loader: ImageMinimizerPlugin.loader,
    options: {
      minimizer: {
        implementation: ImageMinimizerPlugin.sharpMinify,
        options: {
          encodeOptions: {
            jpeg: {
              // https://sharp.pixelplumbing.com/api-output#jpeg
              quality: 100,
            },
            webp: {
              // https://sharp.pixelplumbing.com/api-output#webp
              lossless: true,
            },
            avif: {
              // https://sharp.pixelplumbing.com/api-output#avif
              lossless: true,
            },

            // PNG by default sets the quality to 100%, which is same as lossless
            // https://sharp.pixelplumbing.com/api-output#png
            png: {},

            // GIF does not support lossless compression at all
            // https://sharp.pixelplumbing.com/api-output#gif
            gif: {},
          },
        },
      },
    },
  };

  const svg = {
    loader: ImageMinimizerPlugin.loader,
    options: {
      minimizer: {
        implementation: ImageMinimizerPlugin.svgoMinify,
        options: {
          encodeOptions: {
            // Pass over SVGs multiple times to ensure all optimizations are applied (False by default)
            multipass: true,
            plugins: [
              // Built-in plugin preset enabled by default
              // See: https://github.com/svg/svgo#default-preset
              'preset-default',
            ],
          },
        },
      },
    },
  };

  // Exposes a CSS file as a webpack module
  const css = {
    loader: 'css-loader',
    options: { sourceMap: true },
  };

  // Autoprefix and minify CSS based on browserlist
  const postcss = {
    loader: 'postcss-loader',
    options: {
      sourceMap: true,
      postcssOptions: {
        plugins: [postcssEnv(), cssnano()],
      },
    },
  };

  // Compiles SASS and SCSS into CSS
  const sass = {
    loader: 'sass-loader',
    options: {
      sourceMap: true,
      sassOptions: {
        quietDeps: true,
      },
    },
  };

  // Transpile modern JavaScript based on target environment
  const babel = {
    loader: 'babel-loader',
    options: {
      cacheDirectory: true,
      presets: [
        ['@babel/preset-typescript', { allowDeclareFields: true }],
        [
          '@babel/preset-env',
          {
            corejs: 3,
            loose: true,
            modules: false,
            useBuiltIns: 'usage',
          },
        ],
      ],
      plugins: [['@babel/plugin-transform-runtime', { useESModules: true }]],
    },
  };

  // List of loader pipelines for each set of file types
  const rules = [
    {
      test: /\.(ico|eot|ttf|woff|woff2)$/i,
      type: 'asset/resource',
    },
    {
      test: /\.(jpe?g|png|gif)$/i,
      type: 'asset/resource',
      use: [image],
    },
    {
      test: /\.(svg)$/i,
      type: 'asset/resource',
      use: [svg],
    },
    {
      test: /\.(scss|sass|css)$/i,
      use: [Extract.loader, css, postcss, sass],
    },
    {
      test: /\.(m?js)$/i,
      exclude: /node_modules\/(?!(@fullcalendar|@xikolo\/brand)\/)/,
      use: [babel],
    },
    {
      test: /\.ts$/,
      use: [babel],
      exclude: /node_modules/,
    },
  ];

  return rules;
};
