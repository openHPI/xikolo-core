import Swal from 'sweetalert2';
import ready from './ready';

const xuiSwal = Swal.mixin({
  customClass: {
    confirmButton: 'btn btn-primary',
    cancelButton: 'btn btn-default',
  },

  buttonsStyling: false,
  showCancelButton: true,
  focusConfirm: false,
  focusCancel: true,

  // Prevent sweetalert from breaking our sticky footer styling when
  // opening alerts.
  heightAuto: false,
});

ready(() => {
  // Override the default Rails confirmation dialog with a sweetalert

  // HACK: The 'confirm' event on the document is part of the `jquery_ujs` library.
  // jQuery comes from Sprockets assets.
  // eslint-disable-next-line no-undef
  const $ = jQuery;

  $(document).on('confirm', (event) => {
    event.preventDefault();

    // eslint-disable-next-line no-undef
    const element = $(event.target);
    const message = element.data('confirm');
    const title =
      element.data('confirm-title') || I18n.t('global.are_you_sure');

    // Display prompt
    xuiSwal
      .fire({
        title,
        text: message,
        icon: 'warning',
        confirmButtonText: I18n.t('global.confirm'),
        confirmButtonAriaLabel: I18n.t('global.confirm'),
        cancelButtonText: I18n.t('global.cancel'),
        cancelButtonAriaLabel: I18n.t('global.cancel'),
      })
      .then((result) => {
        if (result.value) {
          // User hits OK
          // Remove data-confirm
          element.data('confirm', null);
          // Re-click link
          element.trigger('click.rails');
          // Replace data-confirm (in case of AJAX update, still want prompt next time)
          element.data('confirm', message);
        }
      });

    // Prevent rails from popping up a browser box, we've already done the work
    return false;
  });
});

export default xuiSwal;
