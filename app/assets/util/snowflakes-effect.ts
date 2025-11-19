/**
 * XI-6736: Seasonal snow effect
 **/

(function () {
  const snowContainer = document.getElementById('snow-container');
  if (!snowContainer) {
    return;
  }

  const createSnowflake = () => {
    const snowflake = document.createElement('div');
    snowflake.className = 'snowflake';
    snowflake.textContent = '❄';

    const startPosition = Math.random() * 100;
    const duration = Math.random() * 8 + 12;

    snowflake.style.left = startPosition + 'vw';
    snowflake.style.animationDuration = duration + 's';
    snowflake.style.opacity = (Math.random() * 0.6 + 0.2).toString();
    snowflake.style.fontSize = Math.random() * 10 + 15 + 'px';

    snowContainer.appendChild(snowflake);

    // Remove after animation completes
    setTimeout(() => {
      snowflake.remove();
    }, duration * 1000);
  };

  const snowInterval = setInterval(createSnowflake, 200);

  setTimeout(() => {
    clearInterval(snowInterval);
  }, 20000);
})();
