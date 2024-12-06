/* eslint-disable global-require */
/* eslint-disable no-param-reassign */
//
import { resolve } from 'path';

import development from './webpack.dev.mjs';
import production from './webpack.prod.mjs';

const DIRNAME = new URL('.', import.meta.url).pathname;

export default async (env = {}, argv = {}) => {
  const settings = {
    mode: 'development',
    root: resolve(DIRNAME, '../..'),
    publicPath: env.publicPath || '/assets/webpack/',
    // Hack to detect if running webpack-dev-server
    devServer: !!argv.host,
  };

  // If NODE_ENV or RAILS_ENV is the to production we use the production mode
  if (
    argv.mode === 'production' ||
    process.env.NODE_ENV === 'production' ||
    process.env.RAILS_ENV === 'production'
  ) {
    settings.mode = 'production';
  }

  // We determine the brand(s) to compile from the `brand` argument. If no
  // argument is given, we will check the BRAND environment variable or fall
  // back to `xikolo`.
  const brand = [env.BRAND, process.env.BRAND, 'xikolo'].find((elem) => elem);

  // Choose production or development config function
  const conf = settings.mode === 'development' ? development : production;
  return conf({ ...settings, brand });
};
