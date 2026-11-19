import $ from 'jquery';
import { turboReady } from '../util/ready';
import { hideLoading, showLoading } from '../util/loading';
import xuiSwal from '../util/swal';
import I18n from '../i18n/i18n';

turboReady(() => {
  $('#generate_ranking_button').on('ajax:success', function () {
    hideLoading();
    return xuiSwal.fire(
      I18n.t('admin.courses.generate_ranking.success.title'),
      '',
      'info',
    );
  });
  $('#generate_ranking_button').on('ajax:beforeSend', function () {
    return showLoading();
  });
  $('#generate_ranking_button').on('ajax:error', function () {
    hideLoading();
    return xuiSwal.fire(
      I18n.t('admin.courses.generate_ranking.error.title'),
      I18n.t('admin.courses.generate_ranking.error.msg'),
      'error',
    );
  });

  $('#course_roa_enabled').on('change', function () {
    if ($(this).is(':checked')) {
      $('#roa_threshold_percentage').show();
    } else {
      $('#roa_threshold_percentage').hide();
    }
    return false;
  });

  $('#course_cop_enabled').on('change', function () {
    if ($(this).is(':checked')) {
      $('#cop_threshold_percentage').show();
    } else {
      $('#cop_threshold_percentage').hide();
    }
    return false;
  });
});
