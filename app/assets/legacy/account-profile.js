/* eslint-disable no-undef */

// We cannot import $ because the bootstrap-editable plugin
// expects it to be globally available.
import 'jquery';
import './bootstrap-editable';

import { showLoading, hideLoading } from '../util/loading';

const service_unavailable = I18n.t('dashboard.profile.service_unavailable');
const error_message = I18n.t('dashboard.profile.error_message');
const email_already_taken = I18n.t('dashboard.profile.email_already_taken');

// Settings for birthdate inline editor
const combodate_format = I18n.t('dashboard.profile.combodate_format');
const combodate_viewformat = I18n.t('dashboard.profile.combodate_viewformat');
const combodate_template = I18n.t('dashboard.profile.combodate_template');
const combodate_emptytext = I18n.t('dashboard.profile.not_set');

const isIE = function () {
  return navigator.userAgent.toLowerCase().indexOf('msie') !== -1;
};

$(function () {
  const ajaxurl = document.querySelector('[data-ajaxurl]').dataset.ajaxurl;

  //Hint: x-editable can not deal with async requests within a success function...
  function doAjaxRequest($element, data, success, error) {
    var result = null;
    try {
      $.ajax(ajaxurl, {
        type: 'POST',
        async: false,
        data: data,
        success: function (msg, newValue) {
          result = success(msg, newValue);
          if (!$element.hasClass('editable-updated'))
            $element.addClass('editable-updated');
        },
        error: function (response) {
          $element.removeClass('editable-updated');
          if (typeof error === 'function') result = error(response);
          if (result) return;
          if (response.status === 500) result = service_unavailable;
          else result = error_message;
        },
      });
    } catch (response) {
      if (typeof error === 'function') error(response);
      result = service_unavailable;
    }
    return result;
  }

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

  $('#display_name').editable({
    success: function (msg, newValue) {
      $('#nav-username').closest('.has-spinner').addClass('loading');
      $('#username_preview').prev('.has-spinner').addClass('loading');
      return doAjaxRequest(
        $('#display_name'),
        {
          display_name: newValue,
        },
        function (msg) {
          $('#nav-username').closest('.has-spinner').removeClass('loading');
          $('#username_preview').prev('.has-spinner').removeClass('loading');
          $('#nav-username').html(msg.user.name);
          $('#username_preview').html(msg.user.name);
          if (msg.user.display_name.length > 0) {
            return $('#display_name').html(msg.user.display_name);
          } else {
            return location.reload();
          }
        },
        function () {
          $('#nav-username').closest('.has-spinner').removeClass('loading');
          $('#username_preview').prev('.has-spinner').removeClass('loading');
        },
      );
    },
  });

  $('#full_name').editable({
    success: function (msg, newValue) {
      $('#nav-username').closest('.has-spinner').addClass('loading');
      $('#username_preview').prev('.has-spinner').addClass('loading');
      return doAjaxRequest(
        $('#full_name'),
        {
          full_name: newValue,
        },
        function (msg) {
          $('#nav-username').closest('.has-spinner').removeClass('loading');
          $('#username_preview').prev('.has-spinner').removeClass('loading');
          $('#nav-username').html(msg.user.name);
          return $('#username_preview').html(msg.user.name);
        },
        function () {
          $('#nav-username').closest('.has-spinner').removeClass('loading');
          $('#username_preview').prev('.has-spinner').removeClass('loading');
        },
      );
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

  $('#email').editable({
    success: function (msg, newValue) {
      showLoading();
      return doAjaxRequest(
        $('#email'),
        {
          email: newValue,
        },
        function (msg) {
          $('#email').html(msg.email);
          return document.location.reload();
        },
        function (response) {
          hideLoading();
          if (
            response.responseText.split(', ').includes('has already been taken')
          )
            return email_already_taken;
        },
      );
    },
  });

  $('#born_at').editable({
    format: combodate_format,
    emptytext: combodate_emptytext,
    viewformat: combodate_viewformat,
    template: combodate_template,
    combodate: {
      language: $('html').attr('lang'),
      minYear: 1910,
      maxYear: new Date().getFullYear(),
    },
    success: function (msg, newValue) {
      if (newValue) {
        newValue = newValue.add('m', -newValue.zone()).toISOString();
      }
      return doAjaxRequest(
        $('#born_at'),
        {
          born_at: newValue,
        },
        function (msg) {
          return $('#born_at').data('value', msg);
        },
      );
    },
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
