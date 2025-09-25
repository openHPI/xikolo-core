/* eslint-disable no-undef */

// We cannot import $ because the bootstrap-editable plugin
// expects it to be globally available.
import 'jquery';
import './bootstrap-editable';
import I18n from 'i18n/i18n';
import ready from 'util/ready';

const isIE = function () {
  return navigator.userAgent.toLowerCase().indexOf('msie') !== -1;
};

ready(() => {
  const service_unavailable = I18n.t('dashboard.profile.service_unavailable');
  const error_message = I18n.t('dashboard.profile.error_message');

  $(function () {
    $('#form-changepassword').hide();

    $('.editable')
      .not('.editable-required')
      .editable({
        success: function () {
          if (!$(this).hasClass('editable-updated'))
            $(this).addClass('editable-updated');
        },
        error: function (response) {
          $(this).removeClass('editable-updated');
          if (response.status === 500) return service_unavailable;
          return error_message;
        },
      });

    $('.editable-required').editable({
      onblur: 'submit',
      success: function () {
        if (!$(this).hasClass('editable-updated'))
          $(this).addClass('editable-updated');
      },
      error: function (response) {
        $(this).removeClass('editable-updated');
        if (response.status === 500) return service_unavailable;
        return error_message;
      },
    });

    $('#changepassword-button').on('click', function (evt) {
      evt.preventDefault();
      $('#form-changepassword').show();
      $('#changepassword').hide();
    });

    $('#changepassword-cancel').on('click', function (evt) {
      evt.preventDefault();
      $('#form-changepassword').hide();
      $('#changepassword').show();
    });

    $('#user_visual').on('click', function (evt) {
      evt.preventDefault();
      if (!isIE()) {
        return $('#user_visual_upload').click();
      } else {
        $('#user_visual_upload').toggleClass('hide');
        return $('#user_visual_submit').toggleClass('hide');
      }
    });

    $('#user_visual_upload').change(function () {
      if (!isIE()) {
        this.form.submit();
      }
    });

    $('#secondary-emails-list').hide();
    $('#secondary-emails-hide-button').hide();
    return $('.secondary-emails-button').on('click', function (evt) {
      evt.preventDefault();
      $('#secondary-emails-list').toggle();
      $('#secondary-emails-show-button').toggle();
      $('#secondary-emails-hide-button').toggle();
    });
  });
});
