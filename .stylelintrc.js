module.exports = {
  defaultSeverity: 'warning',
  extends: [
    'stylelint-config-recommended-scss',
    'stylelint-config-idiomatic-order',
    'stylelint-config-two-dash-bem',
  ],
  rules: {
    // The ruby-sass compiler (using libsass) doesn't support CSS Color
    // Level 4, and therefore does not parse the `rbg(0 0 0 / 5%)`
    // space-separated syntax. Therefore we require numbers for alpha
    // value, and the comma-separated legacy syntax for the rgb
    // function. It also does not support the newer non-global
    // functions.
    'alpha-value-notation': 'number',
    'color-function-notation': 'legacy',
    'scss/no-global-function-names': null,
    'scss/comment-no-empty': null,
  },
};
