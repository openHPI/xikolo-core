module.exports = {
  root: true,
  plugins: ['compat', '@typescript-eslint'],
  extends: [
    'airbnb-base',
    'airbnb-typescript/base',
    'prettier',
    'plugin:compat/recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  parser: '@typescript-eslint/parser',
  globals: {
    __BRAND__: 'readonly',
    __MODE__: 'readonly',
    I18n: 'readonly',
  },
  parserOptions: {
    ecmaVersion: 10,
    sourceType: 'module',
    project: './tsconfig.json',
  },
  env: {
    browser: true,
  },
  settings: {
    'import/resolver': {
      node: {
        paths: ['app/assets'],
      },
      typescript: {},
    },
  },
  rules: {
    'import/no-unresolved': ['error', { ignore: ['jquery'] }],
    complexity: ['error', { max: 9 }],
  },
};
