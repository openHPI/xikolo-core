import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerNewsProgressKpiFormatter,
  registerClientUsageFormatters,
} from './common';

ready(function () {
  const i18nPrefix = 'admin.dashboard.show';

  $('.kpi-item.news-progress .score-card').each(function () {
    registerNewsProgressKpiFormatter(this, i18nPrefix);
  });

  $('.chart-container.client-usage .chart').each(function () {
    registerClientUsageFormatters(this, i18nPrefix);
  });
});
