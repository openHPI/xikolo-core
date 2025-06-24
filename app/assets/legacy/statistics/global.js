import $ from 'jquery';
import ready from '../../util/ready';
import { renderNewsTable } from './common';

ready(function () {
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
});
