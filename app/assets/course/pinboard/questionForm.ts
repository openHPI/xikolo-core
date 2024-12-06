import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';

ready(() => {
  document
    .querySelector('[data-track="form-toggle"]')
    ?.addEventListener('click', () => {
      triggerTrackEvent(
        'toggled_pinboard_question_form',
        window.location.pathname,
        'page',
      );
    });

  // Mark questions as read on mouseenter
  ['.qa-answer.unread', '.comment.unread'].forEach((selector) => {
    document.querySelectorAll(selector).forEach((unread) => {
      unread.addEventListener(
        'mouseenter',
        () => {
          unread.classList.remove('unread');
          unread.classList.add('justread');
        },
        { once: true },
      );
    });
  });
});
