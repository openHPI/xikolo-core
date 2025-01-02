import globals from 'globals';
import pluginJs from '@eslint/js';
import tseslint from 'typescript-eslint';

/** @type {import('eslint').Linter.Config[]} */
export default [
  { files: ['**/*.{js,mjs,cjs,ts}'] },
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        __BRAND__: 'readonly',
        __MODE__: 'readonly',
        I18n: 'readonly',
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
      'app/assets/javascripts', // Ignore legacy assets
    ],
  },
];
