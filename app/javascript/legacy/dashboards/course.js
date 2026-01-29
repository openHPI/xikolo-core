import $ from 'jquery';
import ready from '../../util/ready';
import { registerClientUsageFormatters } from './common';

ready(function () {
  const i18nPrefix = 'admin.course_management.dashboard';

  $('.chart-container.client-usage .chart').each(function () {
    registerClientUsageFormatters(this, i18nPrefix);
  });
});
