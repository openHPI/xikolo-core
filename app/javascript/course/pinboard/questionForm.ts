import { turboReady } from '../../util/ready';

turboReady(() => {
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
