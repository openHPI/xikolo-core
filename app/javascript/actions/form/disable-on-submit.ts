/**
 * Disable a DOM element upon form submission
 *
 * Forms with a `data-disable-on-submit` attribute automatically disable the DOM
 * element referenced by the attribute value once the form is submitted.
 * Only the first matching DOM node will be affected.
 *
 * The primary use case is disabling a submit button to prevent multiple interactions.
 *
 * Important: Deprecated - Rails UJS attributes (disable_with)
 *
 * Rails versions prior to 7 include built-in JavaScript that disables the button upon submission.
 * The usage is deprecated.
 * It is recommended to disable this behavior using `data-disable-with=false` attribute
 * and instead put this JS hook in place.
 *
 * See: https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-submit_tag
 */
import { turboReady } from '../../util/ready';

type Dataset = {
  disableOnSubmit: string;
};

turboReady(() => {
  const forms: NodeListOf<HTMLFormElement> = document.querySelectorAll(
    '[data-disable-on-submit]',
  );

  forms.forEach((form) => {
    form.addEventListener('submit', (event) => {
      // A cancelled submit (e.g. Active Storage intercepting a direct upload)
      // never navigates, so nothing would re-enable the element afterwards.
      if (event.defaultPrevented) return;

      const dataSet = form.dataset as Dataset;
      const target = form.querySelector(dataSet.disableOnSubmit);

      target?.setAttribute('disabled', 'true');
    });
  });
});
