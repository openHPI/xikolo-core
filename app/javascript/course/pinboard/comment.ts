import { turboReady } from '../../util/ready';

const toggleCommentForm = (el: HTMLElement, event: Event) => {
  const relatedElements = [
    '#answer_form_box',
    ...el.dataset.toggleSelector!.split(','),
  ];

  relatedElements.forEach((selector) => {
    const element = document.querySelector(selector)!;
    element.classList.toggle('hidden');
  });

  event.preventDefault();
};

const focusCommentForm = (el: HTMLElement, event: Event) => {
  const textField = document.querySelector<HTMLInputElement>(
    `#${el.dataset.focusId} textarea`,
  );
  textField?.focus();
  event.preventDefault();
};

turboReady(() => {
  document
    .querySelectorAll<HTMLElement>('.js-toggle-comment')
    .forEach((toggleCommentTrigger) => {
      toggleCommentTrigger.addEventListener('click', (event) =>
        toggleCommentForm(toggleCommentTrigger, event),
      );
    });

  document
    .querySelectorAll<HTMLElement>('.js-focus-comment-form')
    .forEach((focusCommentTrigger) => {
      focusCommentTrigger.addEventListener('click', (event) =>
        focusCommentForm(focusCommentTrigger, event),
      );
    });
});
