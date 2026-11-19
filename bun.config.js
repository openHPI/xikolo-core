/*eslint no-undef: "off"*/

import path from 'path';
import fs from 'fs';

const config = {
  sourcemap: 'inline',
  entrypoints: ['app/javascript/main.js'],
  outdir: path.join(process.cwd(), 'app/assets/builds'),
  splitting: true,
  minify: true,
  naming: {
    // We need to bypass the digest step of Propshaft for chunk files
    // otherwise, Propshaft won't find them at runtime.
    // https://github.com/rails/propshaft?tab=readme-ov-file#bypassing-the-digest-step
    chunk: 'chunk-[hash].digested.[ext]',
  },
};

const sourceDir = path.join(process.cwd(), 'app/javascript');
const logError = (error) => {
  console.error('❌ Build failed with error(s)', '\n', error);
};

const build = async () => {
  console.log('🥟 Baking buns...');
  const result = await Bun.build(config);

  if (result.success) {
    console.log('🥟 Bun build successful');
  }
};

const startWatch = () => {
  fs.watch(sourceDir, { recursive: true }, async (_, filename) => {
    console.log(`🥟 File changed: ${filename}. Rebuilding...`);
    try {
      await build();
    } catch (error) {
      logError(error);
    }
  });
  console.log('🥟 Watching for changes...');
};

(async () => {
  try {
    await build();

    if (process.argv.includes('--watch')) {
      startWatch();
    } else {
      process.exit(0);
    }
  } catch (error) {
    logError(error);
  }
})();
