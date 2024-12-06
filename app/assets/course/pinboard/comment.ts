import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';
import { loadForm } from './util';

const toggleCommentForm = (el: HTMLElement, event: Event) => {
  triggerTrackEvent('toggled_add_comment');

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

const loadCommentForm = async (el: HTMLElement, event: Event) => {
  event.preventDefault();

  const { commentId, url } = el.dataset;
  const selector = `#comment-edit-${commentId}`;

  loadForm(url!, selector);
  triggerTrackEvent('clicked_edit_comment', 'comment', commentId);
};

ready(() => {
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

  document
    .querySelectorAll<HTMLElement>('.comment-edit')
    .forEach((commentEditEl) => {
      commentEditEl.addEventListener('click', (event) =>
        loadCommentForm(commentEditEl, event),
      );
    });
});
