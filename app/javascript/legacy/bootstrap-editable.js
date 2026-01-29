/* eslint-disable no-undef */

// The bootstrap editable type 'combodate' needs moment.js
// with locales to format and display the input fields.
import moment from 'moment/min/moment-with-locales';
window.moment = moment;
moment.locale(document.documentElement.lang);

import '../../../vendor/assets/javascripts/bootstrap-editable';

$.fn.editableform.buttons =
  '<button type="submit" class="btn btn-primary btn-sm editable-submit">' +
  '<i class="fa-solid fa-fw fa-check"></i>' +
  '</button>' +
  '<button type="button" class="btn btn-default btn-sm editable-cancel">' +
  '<i class="fa-solid fa-fw fa-times"></i>' +
  '</button>';

$.fn.editable.defaults.mode = 'inline';
