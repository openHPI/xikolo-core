import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerDailyActivityFormatters,
  renderCountriesTable,
  renderCitiesTable,
  renderTopItemTypesTable,
  renderRichTextLinksTable,
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
});
