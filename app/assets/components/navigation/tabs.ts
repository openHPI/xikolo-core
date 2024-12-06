/**
 * Navigation::Tabs
 */

import isMobile from '../../util/media-query';
import ready from '../../util/ready';

const setExpanded = (
  expanded: boolean,
  target: Element,
  button: Element,
  text: string,
) => {
  button.setAttribute('aria-label', text);
  button.setAttribute('title', text);
  target.setAttribute('aria-expanded', expanded.toString());
};

const initToggleButton = (button: Element, tabNavigation: Element) => {
  const showText = button.getAttribute('data-show-text')!;
  const hideText = button.getAttribute('data-hide-text')!;
  const content = tabNavigation.querySelector(
    `[data-id='navigation-tabs__content']`,
  )!;

  button.addEventListener('click', () => {
    const enabled = content.getAttribute('aria-expanded');

    if (enabled === 'true') {
      setExpanded(false, content, button, showText);
    } else {
      setExpanded(true, content, button, hideText);
    }
  });

  // Hide navigation per default on small devices
  if (isMobile()) {
    setExpanded(false, content, button, showText);
  }
};

const initContentToggle = (tabNavigation: Element, content: Element) => {
  const tabs = tabNavigation.querySelectorAll(
    "[role='tab'] button",
  ) as NodeListOf<HTMLButtonElement>;
  const tabPanes = content.querySelectorAll(
    `[role='tabpanel']`,
  ) as NodeListOf<HTMLElement>;

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
      tabPanes.forEach((tabPane) => {
        tabPane.setAttribute('hidden', 'true');
      });

      tabs.forEach((t) => {
        t.parentElement!.classList.remove('navigation-tabs__item--active');
        t.setAttribute('aria-selected', 'false');
      });

      const targetId = tab.getAttribute('aria-controls');
      const targetPane = content.querySelector(`[data-id='${targetId}']`)!;

      targetPane.removeAttribute('hidden');
      tab.setAttribute('aria-selected', 'true');
      tab.parentElement!.classList.add('navigation-tabs__item--active');
    });
  });
};

const initTabNavigation = () => {
  const tabNavigations = document.querySelectorAll(
    "[data-controller='navigation-tabs']",
  );

  tabNavigations.forEach((tabNavigation) => {
    // Attach expandable behavior of content via 'collapsible' config
    const button = tabNavigation.querySelector(
      "[data-id='navigation-tabs-button']",
    );

    if (button) initToggleButton(button, tabNavigation);

    // Attach content toggling behavior via 'contentId' config
    const contentId = tabNavigation.getAttribute('data-content-id');

    if (contentId) {
      const content = document.querySelector(`[data-id='${contentId}']`)!;
      initContentToggle(tabNavigation, content);
    }
  });
};

ready(() => {
  initTabNavigation();
});

/**
 * To access the component in sprockets,
 * we attach it to the window object.
 *
 * This is used when we dynamically load content
 * that renders a TabNavigation.
 *
 * As soon as we don't rely on sprockets anymore,
 * we can change this to an export.
 */

declare global {
  interface Window {
    initTabNavigation: () => void;
  }
}

window.initTabNavigation = initTabNavigation;
