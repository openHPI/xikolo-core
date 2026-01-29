/**
 * Navigation::CourseItemNav
 *
 * - Scroll active item into view on ready
 * - Tracking events
 */

import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';

ready(() => {
  const courseItemNavComponent = document.querySelectorAll(
    "[data-controller~='course-item-nav']",
  );

  if (!courseItemNavComponent) return;

  document
    .querySelector('[data-track="clicked_item_nav_prev"]')
    ?.addEventListener('click', () => {
      triggerTrackEvent('clicked_item_nav_prev');
    });

  document
    .querySelector('[data-track="clicked_item_nav_next"]')
    ?.addEventListener('click', () => {
      triggerTrackEvent('clicked_item_nav_next');
    });

  document.querySelector('.course-nav-item.active')?.scrollIntoView({
    block: 'nearest',
    inline: 'center',
  });
});
