import { turboReady } from '../util/ready';
import $ from 'jquery';

turboReady(() => {
  $('#form-changepassword').hide();

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
});

document.addEventListener('turbo:before-cache', () => {
  if ($('#form-changepassword').length) {
    $('#form-changepassword').hide();
    $('#changepassword').show();
  }
});
