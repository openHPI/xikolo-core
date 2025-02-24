import $ from 'jquery';
import ready from '../../util/ready';
import {
  registerDailyActivityFormatters,
  renderCountriesTable,
  renderCitiesTable,
  renderTopItemsTable,
  renderTopItemTypesTable,
  renderVideoStatisticsTable,
  renderDownloadsTable,
  renderRichTextLinkClicksTable,
  renderRichTextLinksTable,
  renderNewsTable,
  renderPinboardActivityTable,
  renderQuizTable,
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
    $.getJSON(
      '/api/v2/statistics/details/geo/countries.json?course_id=' +
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
      '/api/v2/statistics/details/geo/cities.json?course_id=' +
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
  $('#top-items-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/item_visits/top_items?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderTopItemsTable(element, data);
      },
    );
  });
  $('#top-types-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/item_visits/top_item_types?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderTopItemTypesTable(element, data);
      },
    );
  });

  // videos
  $('#video-statistics-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/videos?course_id=' + element.dataset.courseId,
      function (data) {
        renderVideoStatisticsTable(element, data);
      },
    );
  });

  // downloads
  $('#video-assets-downloads-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/downloads?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderDownloadsTable(element, data);
      },
    );
  });

  // rich texts
  $('#rich-text-link-clicks-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/rich_text_link_clicks?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderRichTextLinkClicksTable(element, data);
      },
    );
  });
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
  $('#teaching-team-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/pinboard/teaching_team.json?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderPinboardActivityTable(element, data);
      },
    );
  });
  $('#most-active-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/pinboard/most_active.json?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderPinboardActivityTable(element, data);
      },
    );
  });

  // quiz
  $('#graded-quiz-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/quiz?embed=avg_submit_duration&type=graded&course_id=' +
        element.dataset.courseId,
      function (data) {
        renderQuizTable(element, data);
      },
    );
  });
  $('#selftest-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/quiz?embed=avg_submit_duration&type=selftest&course_id=' +
        element.dataset.courseId,
      function (data) {
        renderQuizTable(element, data);
      },
    );
  });
  $('#survey-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/quiz?embed=avg_submit_duration&type=survey&course_id=' +
        element.dataset.courseId,
      function (data) {
        renderQuizTable(element, data, false);
      },
    );
  });

  // referrer
  $('#referrer-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/referrers.json?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderReferrerTable(element, data);
      },
    );
  });

  // social
  $('#course-shares-total-table').each(function (_, element) {
    $.getJSON(
      '/api/v2/statistics/details/social_shares.json?course_id=' +
        element.dataset.courseId,
      function (data) {
        renderCourseSharesTable(element, data.total);

        $('#course-shares-7days-table').each(function () {
          renderCourseSharesTable(this, data.last_7_days);
        });
        $('#course-shares-30days-table').each(function () {
          renderCourseSharesTable(this, data.last_30_days);
        });
      },
    );
  });
});
