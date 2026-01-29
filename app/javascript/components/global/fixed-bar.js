/**
 * Fixed element on top of the viewport
 *
 * An element with the data-behavior='fixed' attribute will
 * stick on top of the viewport when scrolling over it.
 *
 */

import ready from '../../util/ready';

ready(() => {
  const element = document.querySelector('[data-behavior="fixed"]');
  if (!element) return;

  const navbarHeight = getComputedStyle(document.body).getPropertyValue(
    '--navbar-height',
  );

  const fixedElement = element.cloneNode(true);
  fixedElement.classList.add('js-fixed');

  const handler = (changes) => {
    changes.forEach((change) => {
      const elementIsNotReached =
        window.scrollY < element.getBoundingClientRect().y;

      if (change.isIntersecting || elementIsNotReached) {
        fixedElement.remove();
      } else {
        document.body.append(fixedElement);
      }
    });
  };

  const observer = new IntersectionObserver(handler, {
    threshold: 1,
    rootMargin: `-${navbarHeight.trim()} 0px`,
  });

  observer.observe(element);
});
