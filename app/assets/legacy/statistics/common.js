import $ from 'jquery';
import moment from 'moment';
import TableBuilder from 'table-builder';
import List from 'list.js';

/* Geo Statistics */
export function renderCountriesTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      country_code: I18n.t('admin.statistics.geo.country_header'),
      distinct_users: I18n.t('admin.statistics.geo.users_header'),
      percentage: I18n.t('admin.statistics.geo.percentage_header'),
    },
    preprocessors: {
      country_code: function (cellData) {
        return I18n.t(
          'admin.statistics.geo.countries.' + cellData.toLowerCase(),
        );
      },
      percentage: function (_, row) {
        const percentage = (
          Math.round(row['relative_users'] * 100) / 100
        ).toFixed(2);
        return percentage + '%';
      },
    },
    data: data,
  });
}

export function renderCitiesTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      city_name: I18n.t('admin.statistics.geo.city_header'),
      country_code: I18n.t('admin.statistics.geo.country_header'),
      distinct_users: I18n.t('admin.statistics.geo.users_header'),
      percentage: I18n.t('admin.statistics.geo.percentage_header'),
    },
    preprocessors: {
      country_code: function (cellData) {
        return I18n.t(
          'admin.statistics.geo.countries.' + cellData.toLowerCase(),
        );
      },
      percentage: function (_, row) {
        const percentage = (
          Math.round(row['relative_users'] * 100) / 100
        ).toFixed(2);
        return percentage + '%';
      },
    },
    data: data,
  });
}

/* News Statistics */
export function renderNewsTable(target, data, hideCourseTitle) {
  const headers = {
    newsTitle: I18n.t('admin.statistics.news.news_title_header'),
    courseTitle: I18n.t('admin.statistics.news.course_title_header'),
    counts:
      I18n.t('admin.statistics.news.total_header') +
      ' / ' +
      I18n.t('admin.statistics.news.success_header') +
      ' / ' +
      I18n.t('admin.statistics.news.error_header') +
      ' / ' +
      I18n.t('admin.statistics.news.disabled_header') +
      ' / ' +
      I18n.t('admin.statistics.news.read_header'),
    newest: I18n.t('admin.statistics.news.newest_header'),
    oldest: I18n.t('admin.statistics.news.oldest_header'),
    state: I18n.t('admin.statistics.news.state_header'),
    progress: I18n.t('admin.statistics.news.progress_header'),
    readstateProgress: I18n.t(
      'admin.statistics.news.readstate_progress_header',
    ),
  };
  if (hideCourseTitle) {
    delete headers.courseTitle;
  }

  _renderStatisticsTable({
    target: target,
    headers: headers,
    preprocessors: {
      counts: function (cellData, row) {
        return (
          row.totalCount +
          ' / ' +
          row.successCount +
          ' / ' +
          row.errorCount +
          ' / ' +
          row.disabledCount +
          ' / ' +
          row.globalReadCount
        );
      },
      newest: _getRelativeTime,
      oldest: _getRelativeTime,
      state: function (cellData) {
        return cellData
          ? I18n.t('admin.statistics.news.state_text.text_' + cellData)
          : '';
      },
      progress: _buildProgressBar,
      readstateProgress: _buildProgressBar,
    },
    data: data,
  });
}

function _getRelativeTime(date) {
  const parsedDate = moment(date);
  return parsedDate.isValid() ? parsedDate.fromNow() : '';
}

function _buildProgressBar(progress) {
  return `
    <label>${progress}%</label>
    <progress value="${progress}" max="100"></progress>
  `;
}

/* Pinboard Statistics */
export function renderPinboardActivityTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      user: I18n.t('admin.statistics.pinboard.member_header'),
      posts: I18n.t('admin.statistics.pinboard.posts_header'),
      threads: I18n.t('admin.statistics.pinboard.threads_header'),
    },
    preprocessors: {
      user: function (cellData) {
        return '<a href="/users/' + cellData.id + '">' + cellData.name + '</a>';
      },
      posts: function (cellData, row) {
        return row.posts;
      },
      threads: function (cellData, row) {
        return row.threads;
      },
    },
    data: data,
  });
}

/* Referrer Statistics */
export function renderReferrerTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      site: I18n.t('admin.statistics.referrer.site_header'),
      count: I18n.t('admin.statistics.referrer.count_header'),
    },
    data: data,
  });
}

/* Social Statistics */
export function renderCourseSharesTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      service: I18n.t('admin.statistics.social.course_shares.service_header'),
      clicks: I18n.t('admin.statistics.social.course_shares.count_header'),
    },
    data: data,
  });
}

/* Activity Statistics */
export function registerDailyActivityFormatters(chart) {
  chart.xLabelFormatter = function (label) {
    return moment(label).format('L');
  };
  chart.yLabelFormatter = function (label) {
    return moment(0).hours(label).format('LT');
  };
  chart.cellLabelFormatter = function (data) {
    var date = moment(data.x).hour(data.y);
    return (
      data.value +
      ' ' +
      I18n.t('admin.statistics.activity.daily_activity.active_users_tooltip') +
      ' on ' +
      date.format('lll') +
      ' (UTC)'
    );
  };
}

/* Item Visits Statistics */
export function renderTopItemsTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      item_title: I18n.t('admin.statistics.item_visits.item_title_header'),
      position: I18n.t('admin.statistics.item_visits.position_header'),
      item_content_type: I18n.t(
        'admin.statistics.item_visits.item_content_type_header',
      ),
      item_exercise_type: I18n.t(
        'admin.statistics.item_visits.item_exercise_type_header',
      ),
      visits: I18n.t('admin.statistics.item_visits.visits_header'),
      user: I18n.t('admin.statistics.item_visits.unique_users_header'),
      actions: I18n.t('admin.statistics.item_visits.actions_header'),
    },
    preprocessors: {
      item_title: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.item_id +
          '" data-sort-value="' +
          cellData +
          '">' +
          cellData +
          '</a>'
        );
      },
      actions: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.item_id +
          '/stats" class="btn btn-xs btn-default mr5">' +
          I18n.t('admin.course_management.dashboard.more_details') +
          '</a>' +
          '<button class="btn btn-xs btn-default mr5" data-behavior="copy-to-clipboard" data-text="' +
          row.item_id +
          '">' +
          I18n.t('admin.statistics.item_visits.copy_id') +
          '</button>'
        );
      },
    },
    data: data,
  });
}

export function renderTopItemTypesTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      type: I18n.t('admin.statistics.item_visits.type_header'),
      visits: I18n.t('admin.statistics.item_visits.visits_header'),
      count: I18n.t('admin.statistics.item_visits.avg_visits_header'),
    },
    preprocessors: {
      count: function (cellData, row) {
        return (row.visits / cellData).toFixed(1);
      },
    },
    data: data,
  });
}

/* Videos */
export function renderVideoStatisticsTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      title: I18n.t('admin.statistics.videos.item_title_header'),
      position: I18n.t('admin.statistics.videos.position_header'),
      plays: I18n.t('admin.statistics.videos.plays_header'),
      duration: I18n.t('admin.statistics.videos.duration_header'),
      avg_farthest_watched: I18n.t(
        'admin.statistics.videos.avg_farthest_watched_header',
      ),
      forward_seeks: I18n.t('admin.statistics.videos.forward_seeks_header'),
      backward_seeks: I18n.t('admin.statistics.videos.backward_seeks_header'),
      actions: I18n.t('admin.statistics.videos.actions_header'),
    },
    preprocessors: {
      title: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '" data-sort-value="' +
          row.title +
          '">' +
          row.title +
          '</a>'
        );
      },
      duration: function (cellData) {
        const minutes = Math.floor(cellData / 60);
        const seconds = cellData - minutes * 60;
        return (
          minutes.toString().padStart(2, '0') +
          ':' +
          seconds.toString().padStart(2, '0')
        );
      },
      avg_farthest_watched: function (cellData) {
        return (cellData * 100).toFixed(2) + '%';
      },
      actions: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '/stats" class="btn btn-xs btn-default mr5">' +
          I18n.t('admin.course_management.dashboard.more_details') +
          '</a>' +
          '<button class="btn btn-xs btn-default mr5" data-behavior="copy-to-clipboard" data-text="' +
          row.id +
          '">' +
          I18n.t('admin.statistics.videos.copy_id') +
          '</button>'
        );
      },
    },
    data: data,
  });
}

/* Downloads */
export function renderDownloadsTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      title: I18n.t('admin.statistics.downloads.item_title_header'),
      position: I18n.t('admin.statistics.downloads.position_header'),
      total_downloads: I18n.t(
        'admin.statistics.downloads.total_downloads_header',
      ),
      hd_video_downloads: I18n.t(
        'admin.statistics.downloads.hd_video_downloads_header',
      ),
      sd_video_downloads: I18n.t(
        'admin.statistics.downloads.sd_video_downloads_header',
      ),
      hls_video_downloads: I18n.t(
        'admin.statistics.downloads.hls_video_downloads_header',
      ),
      slides_downloads: I18n.t(
        'admin.statistics.downloads.slides_downloads_header',
      ),
      audio_downloads: I18n.t(
        'admin.statistics.downloads.audio_downloads_header',
      ),
      transcript_downloads: I18n.t(
        'admin.statistics.downloads.transcript_downloads_header',
      ),
      actions: I18n.t('admin.statistics.downloads.actions_header'),
    },
    preprocessors: {
      title: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '" data-sort-value="' +
          row.title +
          '">' +
          row.title +
          '</a>'
        );
      },
      total_downloads: function (cellData, row) {
        return cellData + ' (' + row.total_downloads_unique_users + ')';
      },
      hd_video_downloads: function (cellData, row) {
        return cellData + ' (' + row.hd_video_downloads_unique_users + ')';
      },
      sd_video_downloads: function (cellData, row) {
        return cellData + ' (' + row.sd_video_downloads_unique_users + ')';
      },
      hls_video_downloads: function (cellData, row) {
        return cellData + ' (' + row.hls_video_downloads_unique_users + ')';
      },
      slides_downloads: function (cellData, row) {
        return cellData + ' (' + row.slides_downloads_unique_users + ')';
      },
      audio_downloads: function (cellData, row) {
        return cellData + ' (' + row.audio_downloads_unique_users + ')';
      },
      transcript_downloads: function (cellData, row) {
        return cellData + ' (' + row.transcript_downloads_unique_users + ')';
      },
      actions: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '/stats" class="btn btn-xs btn-default mr5">' +
          I18n.t('admin.course_management.dashboard.more_details') +
          '</a>' +
          '<button class="btn btn-xs btn-default mr5" data-behavior="copy-to-clipboard" data-text="' +
          row.id +
          '">' +
          I18n.t('admin.statistics.downloads.copy_id') +
          '</button>'
        );
      },
    },
    data: data,
  });
}

/* Rich Texts */
export function renderRichTextLinkClicksTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      title: I18n.t('admin.statistics.rich_texts.item_title_header'),
      position: I18n.t('admin.statistics.rich_texts.position_header'),
      total_clicks: I18n.t('admin.statistics.rich_texts.total_clicks_header'),
      total_clicks_unique_users: I18n.t(
        'admin.statistics.rich_texts.total_clicks_unique_users_header',
      ),
      earliest_timestamp: I18n.t(
        'admin.statistics.rich_texts.earliest_timestamp_header',
      ),
      latest_timestamp: I18n.t(
        'admin.statistics.rich_texts.latest_timestamp_header',
      ),
      actions: I18n.t('admin.statistics.rich_texts.actions_header'),
    },
    preprocessors: {
      title: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '" data-sort-value="' +
          row.title +
          '">' +
          row.title +
          '</a>'
        );
      },
      earliest_timestamp: function (cellData) {
        const parsedDate = moment.utc(cellData);
        return parsedDate.isValid() ? parsedDate.format('lll') : '-';
      },
      latest_timestamp: function (cellData) {
        const parsedDate = moment.utc(cellData);
        return parsedDate.isValid() ? parsedDate.format('lll') : '-';
      },
      actions: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.id +
          '/stats" class="btn btn-xs btn-default mr5">' +
          I18n.t('admin.course_management.dashboard.more_details') +
          '</a>' +
          '<button class="btn btn-xs btn-default mr5" data-behavior="copy-to-clipboard" data-text="' +
          row.id +
          '">' +
          I18n.t('admin.statistics.downloads.copy_id') +
          '</button>'
        );
      },
    },
    data: data,
  });
}

export function renderRichTextLinksTable(target, data) {
  _renderStatisticsTable({
    target: target,
    headers: {
      link: I18n.t('admin.statistics.rich_texts.link_header'),
      total_clicks: I18n.t('admin.statistics.rich_texts.total_clicks_header'),
      total_clicks_unique_users: I18n.t(
        'admin.statistics.rich_texts.total_clicks_unique_users_header',
      ),
      earliest_timestamp: I18n.t(
        'admin.statistics.rich_texts.earliest_timestamp_header',
      ),
      latest_timestamp: I18n.t(
        'admin.statistics.rich_texts.latest_timestamp_header',
      ),
    },
    preprocessors: {
      earliest_timestamp: function (cellData) {
        var parsedDate = moment.utc(cellData);
        return parsedDate.isValid() ? parsedDate.format('lll') : '-';
      },
      latest_timestamp: function (cellData) {
        var parsedDate = moment.utc(cellData);
        return parsedDate.isValid() ? parsedDate.format('lll') : '-';
      },
    },
    data: data,
  });
}

/* Quiz Statistics */
export function renderQuizTable(target, data, showPerformance) {
  if (showPerformance === undefined) showPerformance = true;

  // key order is also column order
  var headers = {
    title: I18n.t('admin.statistics.quiz.item_title_header'),
    position: I18n.t('admin.statistics.quiz.position_header'),
    submission_count: I18n.t('admin.statistics.quiz.submission_count_header'),
    submission_user_count: I18n.t(
      'admin.statistics.quiz.submission_user_count_header',
    ),
  };

  if (showPerformance) {
    headers.avg_performance = I18n.t(
      'admin.statistics.quiz.avg_performance_header',
    );
  }

  headers.avg_submit_duration = I18n.t(
    'admin.statistics.quiz.avg_submit_duration_header',
  );
  headers.actions = I18n.t('admin.statistics.quiz.actions_header');

  _renderStatisticsTable({
    target: target,
    headers: headers,
    preprocessors: {
      title: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.item_id +
          '" data-sort-value="' +
          cellData +
          '">' +
          cellData +
          '</a>'
        );
      },
      avg_performance: function (cellData) {
        return (cellData * 100).toFixed(2) + '%';
      },
      avg_submit_duration: function (cellData, row) {
        if (row.unlimited_time === true)
          return I18n.t('admin.statistics.quiz.unlimited_time');

        return cellData;
      },
      actions: function (cellData, row) {
        return (
          '<a href="/courses/' +
          target.dataset.courseCode +
          '/items/' +
          row.item_id +
          '/stats" class="btn btn-xs btn-default mr5">' +
          I18n.t('admin.course_management.dashboard.more_details') +
          '</a>' +
          '<button class="btn btn-xs btn-default mr5" data-behavior="copy-to-clipboard" data-text="' +
          row.item_id +
          '">' +
          I18n.t('admin.statistics.downloads.copy_id') +
          '</button>'
        );
      },
    },
    data: data,
  });
}

/* Helpers */
function _renderStatisticsTable(options) {
  const table = new TableBuilder({
    class: 'table table-striped table-statistics mt20',
  });
  table.setHeaders(options.headers);
  if (options.preprocessors) {
    for (var column in options.preprocessors) {
      table.setPrism(column, options.preprocessors[column]);
    }
  }
  table.setData(options.data);

  const tableHtml = table.render();

  if (tableHtml) {
    $(options.target).html(tableHtml);

    // sortable columns with list.js
    const valueNames = [];

    // attach sort meta data to table headers
    document
      .querySelectorAll('#' + options.target.id + ' th')
      .forEach(function (e) {
        e.classList.forEach(function (c) {
          // tablebuilder.js generates classes for each header key with -th suffix
          if (c.endsWith('-th')) {
            const sortClass = c.substring(0, c.length - 2) + 'sort';
            e.setAttribute('data-sort', sortClass);
            valueNames.push(sortClass);
          }
        });
        e.classList.add('sort');
      });

    // required class
    document
      .querySelector('#' + options.target.id + ' tbody')
      .classList.add('list');

    // attach sort meta data to table cells
    document
      .querySelectorAll('#' + options.target.id + ' td')
      .forEach(function (e) {
        // in case it should not be sorted by the plain html content, this data attribute can be used
        const optionalSortValue = e.querySelector('[data-sort-value]');

        e.className.split(' ').forEach(function (c) {
          const sortClass = c.substring(0, c.length - 2) + 'sort';

          // tablebuilder.js generates classes for each header key with -td suffix
          if (c.endsWith('-td')) {
            if (optionalSortValue) {
              // actual sort value needs to be added to the <tr>
              e.parentElement.setAttribute(
                'data-' + sortClass,
                optionalSortValue.dataset.sortValue,
              );

              // a different value name syntx is required
              // replace the old one
              const index = valueNames.indexOf(sortClass);
              if (index !== -1) {
                valueNames[index] = { data: [sortClass] };
              }
            } else {
              e.classList.add(sortClass);
            }
          }
        });
      });

    // make table sortable
    new List(options.target.id, { valueNames: valueNames });
  } else {
    const noDataMessage =
      options.noDataMessage || I18n.t('admin.statistics.no_data_message');
    $(options.target).html(
      '<div class="no-data-message">' + noDataMessage + '</div>',
    );
  }
}
