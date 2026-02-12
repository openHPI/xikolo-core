/*eslint no-undef: "off"*/

import path from 'path';
import fs from 'fs';

const config = {
  sourcemap: 'inline',
  entrypoints: [
    'app/javascript/main.js',

    'app/javascript/admin/admin.js',
    'app/javascript/course/course.js',
    'app/javascript/home/home.js',
    'app/javascript/teacher/teacher.js',
    'app/javascript/user/user.ts',
    'app/javascript/video-player/video-player.js',
    'app/javascript/quiz-recap/quiz-recap.ts',

    // Legacy
    'app/javascript/legacy/lanalytics/index.js',
    'app/javascript/legacy/account-profile.js',
    'app/javascript/legacy/quiz/result-box.js',
    'app/javascript/legacy/admin.js',
    'app/javascript/legacy/course.js',

    // Libraries
    'app/javascript/legacy/libraries/dimple.js',
    'app/javascript/legacy/bootstrap-editable.js',
  ],
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

const build = async (config) => {
  const result = await Bun.build(config);

  if (!result.success) {
    if (process.argv.includes('--watch')) {
      console.error('Build failed');
      for (const message of result.logs) {
        console.error(message);
      }
      return;
    } else {
      throw new AggregateError(result.logs, '🥟❌ Build failed');
    }
  }
  console.log('🥟 Bun build complete');
};

(async () => {
  console.log('🥟 Baking buns...');
  await build(config);

  if (process.argv.includes('--watch')) {
    fs.watch(
      path.join(process.cwd(), 'app/javascript'),
      { recursive: true },
      (eventType, filename) => {
        console.log(`🥟 File changed: ${filename}. Rebuilding...`);
        build(config);
      },
    );
  } else {
    process.exit(0);
  }
})();
