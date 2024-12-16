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
  document.addEventListener('confirm', (event) => {
    event.preventDefault();

    // eslint-disable-next-line no-undef
    const element = event.target;
    const message = element.dataset.confirm;
    const title = element.dataset.confirmTitle || I18n.t('global.are_you_sure');

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
          // When the user hits "OK", we retrigger the click event
          // without the `data-confirm` attribute to prevent the popup showing up again.
          element.removeAttribute('data-confirm');
          element.click();
          // In case of an AJAX update, still prompt the user
          // the next time by re-adding the `data-confirm` attribute.
          element.setAttribute('data-confirm', message);
        }
      });

    // Prevent rails from popping up a browser box, we've already done the work
    return false;
  });
});

export default xuiSwal;
