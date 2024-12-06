ready(function () {
  $('.js-submit-confirm').each(function (index, element) {
    $(element).submit(function () {
      if ($(element).data('confirm-message') === '') {
        return true;
      }

      xuiSwal
        .fire({
          title: $(element).data('confirm-title'),
          text: $(element).data('confirm-message'),
          icon: 'warning',
          confirmButtonText:
            $(element).data('confirm-button') || I18n.t('global.confirm'),
          cancelButtonText:
            $(element).data('cancel-button') || I18n.t('global.cancel'),
        })
        .then(function (result) {
          if (result.value) {
            showLoading();
            $(element).off('submit');
            $(element).submit();
          } else {
            $(element).data('confirmation-answer', false);
          }
        });

      return false;
    });
  });

  $('.js-swal-popup').each(function (index, element) {
    $(element).click(function (e) {
      e.preventDefault();

      xuiSwal.fire({
        title: $(element).data('popup-title'),
        text: $(element).data('popup-message'),
        icon: 'info',
      });
    });
  });

  // HTML5 form fallback for older browsers
  $('button[form]').each(function (index, element) {
    $(element).click(function () {
      $('#' + $(element).attr('form')).submit();
    });
  });
});

// Submits a forms while also triggering onsubmit event handlers
function submit_form_force_events(form) {
  // Get the form element's document to create the input control with
  // (this way will work across windows in IE8)
  var button = form.ownerDocument.createElement('input');
  // Make sure it can't be seen/disrupts layout (even momentarily)
  button.style.display = 'none';
  // Make it such that it will invoke submit if clicked
  button.type = 'submit';
  // Append it and click it
  form.appendChild(button).click();

  // If it was prevented, make sure we don't get a build up of buttons
  form.removeChild(button);
}
