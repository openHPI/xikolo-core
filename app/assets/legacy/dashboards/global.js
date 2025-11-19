import $ from 'jquery';
import ready from '../../util/ready';
import { registerClientUsageFormatters } from './common';

ready(function () {
  const i18nPrefix = 'admin.dashboard.show';

  $('.chart-container.client-usage .chart').each(function () {
    registerClientUsageFormatters(this, i18nPrefix);
  });
});
