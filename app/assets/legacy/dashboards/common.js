import moment from 'moment';

export function registerNewsProgressKpiFormatter(element, i18nPrefix) {
  if (!element) return;

  element.valueFormatter = function (value) {
    if (typeof value.progress === 'undefined') {
      return 'n/a';
    }
    var label = value.progress + '%';
    if (value.state) {
      var localizedState = I18n.t(
        i18nPrefix +
          '.kpis.misc.recent_news_progress.state_text.text_' +
          value.state,
      );
      label += ' (' + localizedState + ')';
    }
    return label;
  };
}

export function registerQuizPerformanceKpiFormatter(element) {
  if (!element) return;

  element.valueFormatter = function (value) {
    return (value * 100).toFixed(2) + '%';
  };
}

export function registerWeekdayActivityFormatters(element, i18nPrefix) {
  if (!element) return;

  element.xLabelFormatter = function (label) {
    return moment.weekdaysShort(label);
  };
  element.yLabelFormatter = function (label) {
    return moment(0).hours(label).format('LT');
  };
  element.cellLabelFormatter = function (data) {
    return (
      data.value.toLocaleString('en-US', { maximumFractionDigits: 2 }) +
      ' ' +
      I18n.t(i18nPrefix + '.weekday_activity.active_users_tooltip')
    );
  };
}

export function registerClientUsageFormatters(element, i18nPrefix) {
  if (!element) return;

  element.labelFormatter = function (label) {
    return I18n.t(i18nPrefix + '.client_usage.label_' + label);
  };
  element.valueFormatter = function (value) {
    return value + ' ' + I18n.t(i18nPrefix + '.client_usage.learners_tooltip');
  };
}
