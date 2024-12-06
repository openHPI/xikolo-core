import Cookies from 'js-cookie';
import ready from 'util/ready';

// Let teachers pin the teacher navigation on the side of their browser window.
// This preference is remembered on the device.

const COOKIE_NAME = 'pin_teacher_nav';

const isPinned = () => Cookies.get(COOKIE_NAME);
const pin = () => Cookies.set(COOKIE_NAME, '1');
const unpin = () => Cookies.remove(COOKIE_NAME);

ready(() => {
  const trigger = document.querySelector('[data-pin-teacher-nav]');

  if (!trigger) return;

  trigger.addEventListener('click', () => {
    if (isPinned()) {
      unpin();
    } else {
      pin();
    }

    document
      .querySelector(trigger.dataset.pinTeacherNav)
      .toggleAttribute('data-pinned');
  });
});
