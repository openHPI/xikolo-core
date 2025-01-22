import ready from 'util/ready';
import swal from 'util/swal';
import I18n from 'i18n/i18n';

ready(() => {
  const unprotectedRadio = document.querySelector('input[value="unprotected"]');
  const anonymizedRadio = document.querySelector('input[value="anonymized"]');

  if (!unprotectedRadio || !anonymizedRadio) return;

  const alertConfig = {
    customClass: {
      confirmButton: 'btn btn-danger',
      cancelButton: 'btn btn-default',
    },
    title: I18n.t('simple_form.prompts.lti_provider.title'),
    text: I18n.t('simple_form.prompts.lti_provider.text'),
    icon: 'warning',
    showCancelButton: true,
    focusCancel: true,
    allowOutsideClick: false,
    buttonsStyling: false,
    cancelButtonText: I18n.t('simple_form.prompts.lti_provider.cancel'),
    confirmButtonText: I18n.t('simple_form.prompts.lti_provider.confirm'),
  };

  const resetToAnonymized = () => {
    anonymizedRadio.checked = true;
    unprotectedRadio.checked = false;
  };

  unprotectedRadio.addEventListener(
    'change',
    () => {
      swal.fire(alertConfig).then((result) => {
        if (result.dismiss === 'cancel') {
          resetToAnonymized();
        }
      });
    },
    {
      once: true,
    },
  );
});
