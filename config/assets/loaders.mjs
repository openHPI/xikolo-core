import Extract from 'mini-css-extract-plugin';

import cssnano from 'cssnano';
import postcssEnv from 'postcss-preset-env';

export default async () => {
  // The image loader optimizes images before emitting
  // them into the bundle.
  const image = {
    loader: 'image-webpack-loader',
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
      test: /\.(jpe?g|png|gif|svg)$/i,
      type: 'asset/resource',
      use: [image],
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
