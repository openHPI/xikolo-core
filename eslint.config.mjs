import globals from 'globals';
import pluginJs from '@eslint/js';
import tseslint from 'typescript-eslint';

/** @type {import('eslint').Linter.Config[]} */
export default [
  { files: ['app/javascript/**/*.{js,mjs,cjs,ts}'] },
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        I18n: 'readonly',
        $: 'readonly', // app/javascript/legacy/initializers.js
        jQuery: 'readonly', // app/javascript/legacy/initializers.js
      },
    },
  },
  pluginJs.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      'no-console': ['warn'],
    },
  },
  {
    ignores: [
      'vendor/assets/javascripts', // Ignore vendor assets
    ],
  },
];
