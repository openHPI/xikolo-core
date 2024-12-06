import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';

/**
 * Toggle text and icon on subscription trigger
 * @param el
 */
const toggleSubscription = (el: HTMLElement) => {
  const element = el;
  const oldText = el.innerText;
  const newText = el.dataset.toggletext;

  element.innerText = newText || '';
  element.dataset.toggletext = oldText;

  const icon = document.querySelector('.subscription_icon');
  icon?.classList.toggle('fa-solid');
  icon?.classList.toggle('fa-regular');

  triggerTrackEvent('toggled_subscription');
};

ready(() => {
  const toggleSubscriptionTrigger = document.querySelector<HTMLElement>(
    '#toggle_subscription',
  );

  if (toggleSubscriptionTrigger) {
    toggleSubscriptionTrigger.addEventListener('click', () =>
      toggleSubscription(toggleSubscriptionTrigger),
    );
  }
});
