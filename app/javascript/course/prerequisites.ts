import ready from '../util/ready';
import swal from '../util/swal';
import fetch from '../util/fetch';
import handleError from '../util/error';
import I18n from '../i18n/i18n';

const fireReactivateAlert = (e: Event) => {
  const reactivateButton = e.target as HTMLButtonElement;
  if (!reactivateButton) return;

  const { courseTitle } = reactivateButton.dataset;
  const { courseId } = reactivateButton.dataset;
  const reactivationUrl = reactivateButton.dataset.url;

  if (!courseTitle || !courseId || !reactivationUrl) return;

  swal
    .fire({
      title: I18n.t('courses.prerequisites.reactivation_modal.title', {
        course: courseTitle,
      }),
      html: I18n.t('courses.prerequisites.reactivation_modal.text'),
      icon: 'warning',
      confirmButtonText: I18n.t(
        'courses.prerequisites.reactivation_modal.button_confirm',
      ),
      confirmButtonAriaLabel: I18n.t(
        'courses.prerequisites.reactivation_modal.button_confirm',
      ),
      cancelButtonText: I18n.t(
        'courses.prerequisites.reactivation_modal.button_cancel',
      ),
      cancelButtonAriaLabel: I18n.t(
        'courses.prerequisites.reactivation_modal.button_cancel',
      ),
      preConfirm: () =>
        fetch(reactivationUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ reactivate: courseId }),
        })
          .then((response) => {
            if (!response.ok) {
              swal.showValidationMessage(
                I18n.t('courses.prerequisites.reactivation_modal.error'),
              );
            }
          })
          .catch((error) => {
            handleError(undefined, error, false);
          }),
      showLoaderOnConfirm: true,
    })
    .then((result) => {
      if (result.value) {
        swal
          .fire({
            title: I18n.t('courses.prerequisites.success_modal.title'),
            text: I18n.t('courses.prerequisites.success_modal.text', {
              course: courseTitle,
            }),
            icon: 'success',
            showCancelButton: false,
          })
          .then(() => {
            document.location.reload();
          });
      }
    });
};

ready(() => {
  const reactivateButtons = document.querySelectorAll(
    '[data-behavior=reactivate-prerequisite]',
  );

  reactivateButtons.forEach((btn) => {
    btn.addEventListener('click', fireReactivateAlert);
  });
});
