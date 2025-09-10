import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerDailyActivityFormatters,
  renderCountriesTable,
  renderCitiesTable,
  renderTopItemTypesTable,
  renderVideoStatisticsTable,
  renderRichTextLinksTable,
  renderNewsTable,
  renderPinboardActivityTable,
} from './common';

ready(function () {
  // activity
  $('.chart-container.daily-activity .chart').each(function () {
    registerDailyActivityFormatters(this);
  });

  // geo
  $('#country-table').each(function (_, element) {
    $.getJSON(
      '/admin/detail_statistics/countries?course_id=' +
        element.dataset.courseId +
        '&start_date=' +
        element.dataset.startDate +
        '&end_date=' +
        element.dataset.endDate,
      function (data) {
        renderCountriesTable(element, data);
      },
    );
  });
  $('#city-table').each(function (_, element) {
    $.getJSON(
      '/admin/detail_statistics//cities?course_id=' +
        element.dataset.courseId +
        '&start_date=' +
        element.dataset.startDate +
        '&end_date=' +
        element.dataset.endDate,
      function (data) {
        renderCitiesTable(element, data);
      },
    );
  });

  // item visits
  $('#top-types-table').each(function (_, element) {
    $.getJSON(
      '/admin/detail_statistics/top_item_types?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderTopItemTypesTable(element, data);
      },
    );
  });

  // videos
  $('#video-statistics-table').each(function (_, element) {
    $.getJSON(
      '/admin/detail_statistics/videos?course_id=' + element.dataset.courseId,
      function (data) {
        renderVideoStatisticsTable(element, data);
      },
    );
  });

  // rich texts
  $('#rich-text-links-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/item_details/rich_text_links?item_id=' +
        element.dataset.itemId,
      function (data) {
        renderRichTextLinksTable(element, data);
      },
    );
  });

  // news
  $('#news-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/news_statistics?course=' + element.dataset.courseId,
      function (data) {
        renderNewsTable(element, data.news_statistics, true);
      },
    );
  });

  // pinboard
  $('#most-active-table').each(function (_, element) {
    $.getJSON(
      '/admin/detail_statistics/most_active?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderPinboardActivityTable(element, data);
      },
    );
  });
});
