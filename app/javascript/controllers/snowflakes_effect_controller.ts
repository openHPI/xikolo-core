import { Controller } from '@hotwired/stimulus';
import { isScreenSizeSmall } from '../util/media-query';

export default class extends Controller {
  declare isSnowing: boolean;
  declare snowInterval: ReturnType<typeof setInterval> | null;
  declare autoStopTimeout: ReturnType<typeof setTimeout> | null;
  declare snowContainer: HTMLElement;

  connect() {
    this.isSnowing = false;
    this.snowInterval = null;
    this.autoStopTimeout = null;
    this.snowContainer = document.getElementById(
      'snow-container',
    ) as HTMLElement;

    if (
      !this.userPrefersReducedMotion() &&
      localStorage.getItem('snowfallEnabled') !== 'false'
    ) {
      this.startSnowfall();
    }
  }

  disconnect() {
    this.removeSnowflakes();
    this.stopSnowfall();
  }

  userPrefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  startSnowfall() {
    if (!this.snowContainer) {
      return;
    }

    if (this.snowInterval) {
      clearInterval(this.snowInterval);
    }
    if (this.autoStopTimeout) {
      clearTimeout(this.autoStopTimeout);
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
      snowflake.setAttribute('aria-hidden', 'true');
      snowflake.className = 'snowflake';
      snowflake.textContent = '❄';

      const startPosition = Math.random() * 100;
      const duration = Math.random() * 8 + 12;

      snowflake.style.left = startPosition + 'vw';
      snowflake.style.animationDuration = duration + 's';
      snowflake.style.opacity = (Math.random() * 0.6 + 0.2).toString();
      snowflake.style.fontSize = Math.random() * 10 + settings.fontSize + 'px';

      this.snowContainer.appendChild(snowflake);

      // Remove after animation completes
      setTimeout(() => {
        snowflake.remove();
      }, duration * 1000);
    };

    this.snowInterval = setInterval(createSnowflake, settings.intervalMs);
    this.isSnowing = true;

    this.autoStopTimeout = setTimeout(() => {
      this.stopSnowfall();
    }, 20000);
  }

  stopSnowfall() {
    if (this.snowInterval) {
      clearInterval(this.snowInterval);
      this.snowInterval = null;
    }
    if (this.autoStopTimeout) {
      clearTimeout(this.autoStopTimeout);
      this.autoStopTimeout = null;
    }
    this.isSnowing = false;
  }

  removeSnowflakes() {
    const snowflakes = document.querySelectorAll('.snowflake');
    snowflakes.forEach((snowflake) => snowflake.remove());
  }

  toggleSnowfall() {
    if (this.isSnowing) {
      this.stopSnowfall();
      this.removeSnowflakes();
      localStorage.setItem('snowfallEnabled', 'false');
    } else {
      this.startSnowfall();
      localStorage.setItem('snowfallEnabled', 'true');
    }
  }
}
