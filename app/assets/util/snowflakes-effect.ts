/**
 * XI-6736: Seasonal snow effect
 **/

import { isScreenSizeSmall } from './media-query';

(function () {
  const snowContainer = document.getElementById('snow-container');
  if (!snowContainer) {
    return;
  }

  // Respect user motion preferences
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)',
  ).matches;

  if (prefersReducedMotion) {
    return;
  }

  const settings = isScreenSizeSmall()
    ? {
        intervalMs: 400, // slower spawn rate => less snowflakes
        fontSize: 10,
      }
    : {
        intervalMs: 200,
        fontSize: 15,
      };

  const createSnowflake = () => {
    const snowflake = document.createElement('div');
    snowflake.className = 'snowflake';
    snowflake.textContent = '❄';

    const startPosition = Math.random() * 100;
    const duration = Math.random() * 8 + 12;

    snowflake.style.left = startPosition + 'vw';
    snowflake.style.animationDuration = duration + 's';
    snowflake.style.opacity = (Math.random() * 0.6 + 0.2).toString();
    snowflake.style.fontSize = Math.random() * 10 + settings.fontSize + 'px';

    snowContainer.appendChild(snowflake);

    // Remove after animation completes
    setTimeout(() => {
      snowflake.remove();
    }, duration * 1000);
  };

  const snowInterval = setInterval(createSnowflake, settings.intervalMs);

  setTimeout(() => {
    clearInterval(snowInterval);
  }, 20000);
})();
