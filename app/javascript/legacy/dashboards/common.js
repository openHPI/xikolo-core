export function registerClientUsageFormatters(element, i18nPrefix) {
  if (!element) return;

  element.labelFormatter = function (label) {
    return I18n.t(i18nPrefix + '.client_usage.label_' + label);
  };
  element.valueFormatter = function (value) {
    return value + ' ' + I18n.t(i18nPrefix + '.client_usage.learners_tooltip');
  };
}
