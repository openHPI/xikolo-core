import { ContentType } from './form-types';

const isVideo = (el: ContentType) => el === 'video';
const isRichText = (el: ContentType) => el === 'rich_text';

export const setVisibility = (display: string, selectors: string[]) =>
  selectors.forEach((selector) => {
    document.querySelectorAll(selector).forEach((element) => {
      const el = element as HTMLElement;
      el.hidden = display === 'hide';
    });
  });

export const hideAndUncheckSwitch = (
  containerSelector: string,
  checkboxSelector: string,
) => {
  const container = document.querySelector<HTMLElement>(containerSelector);
  const checkbox = document.querySelector<HTMLInputElement>(checkboxSelector);

  if (!container || !checkbox) return;
  container.hidden = true;
  checkbox.checked = false;
};

export const hidePublicDescription = () => {
  const publicDescription = document.querySelector<HTMLElement>(
    '#public-description-markdown',
  );
  if (!publicDescription) return;

  publicDescription.hidden = true;
  // Reset markdown
  const publicDescriptionInput = publicDescription.querySelector<HTMLElement>(
    '[contenteditable="true"]',
  );
  publicDescriptionInput!.innerHTML = '';
};

export const setDefaultTypes = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  const exerciseSelector = exerciseTypeElem;
  // Set exercise type default according to the new content type
  exerciseSelector.value =
    isRichText(contentTypeElem.value as ContentType) ||
    isVideo(contentTypeElem.value as ContentType)
      ? ''
      : 'selftest';

  // Trigger a change event for the exercise type to adjust the controls
  // according to the new element type (just set above)
  exerciseSelector.dispatchEvent(
    new Event('change', {
      bubbles: false,
      cancelable: true,
    }),
  );
};

export const hideAllInputs = () => {
  setVisibility('hide', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_max_points',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
    '#featured-switch',
    '#icon-type-select',
  ]);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hideAndUncheckSwitch('#proctoring-switch', '#proctoring-checkbox');
  hidePublicDescription();
};
