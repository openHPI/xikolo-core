import ready from 'util/ready';

ready(() => {
  const validControllerAction = document.querySelector(
    'body.lti-providers-controller.index-action, body.lti-providers-controller.create-action',
  );
  if (!validControllerAction) return;

  const btnAddLtiProviderForm = document.querySelector(
    '#js-lti-provider-form-add',
  );
  const formNewLtiProvider = document.querySelector(
    '#js-form-new-lti-provider',
  );

  if (!btnAddLtiProviderForm) return;
  if (!formNewLtiProvider) return;

  btnAddLtiProviderForm.addEventListener('click', () => {
    formNewLtiProvider.hidden = false;
    btnAddLtiProviderForm.hidden = true;
  });

  const btnsLtiCancelProviderForm = document.querySelectorAll(
    '.js-lti-provider-form-cancel',
  );
  btnsLtiCancelProviderForm.forEach((elem) => {
    elem.addEventListener('click', (event) => {
      const formClosest = event.target.closest('.form_wrapper');

      if (!formClosest) return;
      formClosest.hidden = true;
      btnAddLtiProviderForm.hidden = false;
    });
  });

  const linksEditLtiProvider = document.querySelectorAll(
    'a.js-lti-provider-edit-form-add',
  );
  linksEditLtiProvider.forEach((elem) => {
    elem.addEventListener('click', () => {
      const formEdit = document.querySelector(
        `#js-form-edit-lti-provider-${elem.dataset.providerId}`,
      );

      if (!formEdit) return;
      formEdit.hidden = false;
    });
  });
});
