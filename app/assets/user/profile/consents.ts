import ready from '../../util/ready';
import fetch from '../../util/fetch';
import handleError from '../../util/error';

const submitFormChange = async (form: HTMLFormElement) => {
  const url = form.dataset.url!;
  const formData = new FormData(form);

  try {
    const response = await fetch(url, {
      method: 'PUT',
      body: formData,
    });
    if (!response.ok) {
      throw new Error(response.statusText);
    }
    return await response.json();
  } catch (error) {
    return handleError(undefined, error);
  }
};

ready(() => {
  document.querySelectorAll('[data-profile-consent]').forEach((consentForm) => {
    const form = consentForm as HTMLFormElement;

    form.addEventListener('change', async () => {
      const data = await submitFormChange(form);

      // If exists, remove previous "consented at" information.
      form.querySelector('p')?.remove();
      if (data) {
        // Update "consented_at" information with the new response.
        const consentInfo = form.querySelector(
          '[data-behavior="consent-info"]',
        ) as HTMLElement;
        const templateContent = document.querySelector(
          '[data-behavior="consent-info-template"]',
        )!.innerHTML;

        // Create HTML elements based on the template
        // with the consented_at_msg response
        const newContent = document.createElement('div');
        newContent.innerHTML = templateContent;
        const newContentMsg = newContent.querySelector(
          '[data-behavior="consent-msg"]',
        );
        newContentMsg!.innerHTML = data[0].consented_at_msg;

        // Append it into the document
        consentInfo.appendChild(newContent);
      }
    });
  });
});
