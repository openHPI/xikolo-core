import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerNewsProgressKpiFormatter,
  registerClientUsageFormatters,
  registerQuizPerformanceKpiFormatter,
} from './common';

ready(function () {
  const i18nPrefix = 'admin.course_management.dashboard';

  $('.kpi-item.news-progress .score-card').each(function () {
    registerNewsProgressKpiFormatter(this, i18nPrefix);
  });

  $('.chart-container.client-usage .chart').each(function () {
    registerClientUsageFormatters(this, i18nPrefix);
  });

  $('.kpi-item.quiz-performance .score-card').each(function () {
    registerQuizPerformanceKpiFormatter(this);
  });
});
