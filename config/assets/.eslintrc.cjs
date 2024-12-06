module.exports = {
  parserOptions: {
    // Import at newer ECMA version to support `import.meta` required to
    // get current file directory.
    ecmaVersion: 13,
  },
  rules: {
    // ESLint always complains about `Unexpected use of file extension
    // "mjs" for "./webpack.dev.mjs"`, but the mjs extension _is_
    // needed.
    'import/extensions': 0,
  },
};
