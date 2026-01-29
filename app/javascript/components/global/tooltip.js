/**
 * Tooltip
 *
 * Usage:
 * 1. Add the attribute data-tooltip to the item or
 * items you want to have a tooltip in.
 *
 * 2.1. For a simple tooltip, add the text as a string to the data-tooltip attribute.
 * For accessibility, it is also recommended to add the aria-label.
 *
 * 2.2. For a more advanced tooltip, add a json object with key values pairs.
 * e.g: data-tooltip='{"title":"Text", "subtitle":"Text with different style"}'
 * Each entry can be styled independently with the data-class defined by the key
 * (e.g. [data-class="subtitle"])
 *
 * The tooltip container with attribute [data-id='tooltip'] already exists
 * in the application.html.slim
 */

import ready from '../../util/ready';

const TOOLTIP_CONTAINER = 'tooltip';

const calculatePosition = (container, element) => {
  const rect = element.getBoundingClientRect();
  const dimension = {
    x: container.offsetWidth,
    y: container.offsetHeight,
  };
  let x = rect.left - dimension.x / 2 + rect.width / 2 + window.scrollX;
  // Calculate y position and add 15px margin for a better fit
  const y = rect.top - dimension.y + window.scrollY - 15;
  let xOverflow = 0;

  // Avoid container overflowing window
  if (x < 0) {
    xOverflow = (x / dimension.x) * 100;
    x = 0;
  }

  if (x + dimension.x > document.body.clientWidth) {
    xOverflow =
      ((x + dimension.x - document.body.clientWidth) / dimension.x) * 100;
    x = document.body.clientWidth - dimension.x;
  }

  return {
    x,
    y,
    xOverflow,
  };
};

const showTooltip = (template, element) => {
  const container = document.querySelector(`[data-id="${TOOLTIP_CONTAINER}"]`);
  // Place the build tooltip content to the container content
  container.innerHTML = template.innerHTML;
  container.hidden = false;

  // Determine new position for the tooltip container
  const { x, y, xOverflow } = calculatePosition(container, element);
  container.style.top = `${y}px`;
  container.style.left = `${x}px`;

  // Determine new arrow position
  if (xOverflow) {
    document.documentElement.style.setProperty(
      '--tooltip-arrow-position',
      `${50 + xOverflow}%`,
    );
  } else {
    document.documentElement.style.setProperty(
      '--tooltip-arrow-position',
      '50%',
    );
  }
};

const buildTooltip = (element) => {
  const template = document.createElement('div');
  let tooltipContent = element.getAttribute('data-tooltip');
  let type;

  try {
    tooltipContent = JSON.parse(tooltipContent);
    type = 'advanced';
  } catch {
    type = 'simple';
  }

  if (type === 'advanced') {
    const entries = Object.entries(tooltipContent);
    entries.forEach(([key, value]) => {
      const tooltipContentTemplate = `<span data-class="${key}">${value}</span>`;
      template.insertAdjacentHTML('beforeend', tooltipContentTemplate);
    });
  } else {
    template.insertAdjacentHTML('beforeend', `<span>${tooltipContent}</span>`);
  }

  return template;
};

/**
 * Go through all elements with a tooltip data attribute and initialize them.
 */
ready(() => {
  const container = document.querySelector(`[data-id="${TOOLTIP_CONTAINER}"]`);
  const elementsWithTooltip = document.querySelectorAll('[data-tooltip]');

  elementsWithTooltip.forEach((element) => {
    const template = buildTooltip(element);

    element.addEventListener('mouseenter', () => {
      showTooltip(template, element);
    });

    element.addEventListener('mouseleave', () => {
      container.hidden = true;
    });
  });
});
