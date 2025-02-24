import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerDailyActivityFormatters,
  renderCountriesTable,
  renderCitiesTable,
  renderNewsTable,
  renderReferrerTable,
  renderCourseSharesTable,
} from './common';

ready(function () {
  // activity
  $('.chart-container.daily-activity .chart').each(function () {
    registerDailyActivityFormatters(this);
  });

  // geo
  $('#country-table').each(function (_, element) {
    $.getJSON('/api/v2/statistics/details/geo/countries.json', function (data) {
      renderCountriesTable(element, data);
    });
  });
  $('#city-table').each(function (_, element) {
    $.getJSON('/api/v2/statistics/details/geo/cities.json', function (data) {
      renderCitiesTable(element, data);
    });
  });

  // news
  $('#global-news-table').each(function (_, element) {
    $.getJSON('/api/v2/news_statistics?global=true', function (data) {
      renderNewsTable(element, data.news_statistics, true);
    });
  });
  $('#course-news-table').each(function (_, element) {
    $.getJSON('/api/v2/news_statistics', function (data) {
      renderNewsTable(element, data.news_statistics);
    });
  });

  // referrer
  $('#referrer-table').each(function (_, element) {
    $.getJSON('/api/v2/statistics/details/referrers.json', function (data) {
      renderReferrerTable(element, data);
    });
  });

  // social
  $('#course-shares-total-table').each(function (_, element) {
    $.getJSON('/api/v2/statistics/details/social_shares.json', function (data) {
      renderCourseSharesTable(element, data.total);

      $('#course-shares-7days-table').each(function () {
        renderCourseSharesTable(this, data.last_7_days);
      });
      $('#course-shares-30days-table').each(function () {
        renderCourseSharesTable(this, data.last_30_days);
      });
    });
  });
});
