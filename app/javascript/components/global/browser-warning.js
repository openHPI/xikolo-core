import Cookies from 'js-cookie';
import { turboReady } from '../../util/ready';

turboReady(() => {
  const dismissButton = document.querySelector(
    '[data-browser-warning="dismiss"]',
  );

  if (!dismissButton) return;

  dismissButton.addEventListener('click', () => {
    Cookies.set('_browser_warning', 'hide', { expires: 365, path: '/' });

    const alert = document.querySelector('[data-browser-warning="alert"]');
    if (alert) {
      alert.classList.add('hidden');
    }
  });
});
