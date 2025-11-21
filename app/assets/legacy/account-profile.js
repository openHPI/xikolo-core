/* eslint-disable no-undef */
import ready from 'util/ready';

ready(() => {
  $(function () {
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
});
