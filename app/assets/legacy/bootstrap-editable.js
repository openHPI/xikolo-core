/* eslint-disable no-undef */
// We cannot import the $ because the bootstrap-editable plugin
// expects it to be globally available.
import 'jquery';
import '../../../vendor/assets/javascripts/bootstrap-editable';

$.fn.editableform.buttons =
  '<button type="submit" class="btn btn-primary btn-sm editable-submit">' +
  '<i class="fa-solid fa-fw fa-check"></i>' +
  '</button>' +
  '<button type="button" class="btn btn-default btn-sm editable-cancel">' +
  '<i class="fa-solid fa-fw fa-times"></i>' +
  '</button>';

$.fn.editable.defaults.mode = 'inline';
