import Cookies from 'js-cookie';
import ready from '../../util/ready';

ready(() => {
  const systemAlerts = document.querySelectorAll("[data-id='system-alerts']");

  systemAlerts.forEach((alerts) => {
    const closeBtn = alerts.querySelector(
      "[data-id='system-alerts__close-btn']",
    );
    const toggle = alerts.querySelector("[data-id='system-alerts__toggle']");

    if (!closeBtn || !toggle) return;

    alerts.addEventListener('click', () => {
      toggle.setAttribute('aria-expanded', true);
    });

    closeBtn.addEventListener('click', (e) => {
      toggle.setAttribute('aria-expanded', false);

      // Mark all current alerts as seen when closing the dropdown
      const { systemAlertCookie } = alerts.dataset;
      Cookies.set('seen_alerts', systemAlertCookie);

      // do not call click event on system-alert (parent)
      e.stopPropagation();
    });
  });
});
