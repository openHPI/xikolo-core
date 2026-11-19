/**
 * Fetches new content from the current window location
 *
 * Required data attributes in the HTML:
 * - data-behavior 'load-more' to trigger the fetch on click
 *   Important: Provide data-id in the dataset as a target where to add the new content
 * - data-id 'load-more__indicator' is displayed during the fetching
 * - data-id 'load-more__error-message' is displayed if an error occurs while fetching
 */

import { turboReady } from '../../util/ready';
import fetch from '../../util/fetch';

turboReady(() => {
  const button = document.querySelector('[data-behavior="load-more"]');
  const loadingIndicator = document.querySelector(
    '[data-id="load-more__indicator"]',
  );
  const errorMessage = document.querySelector(
    '[data-id="load-more__error-message"]',
  );

  if (!button || !loadingIndicator || !errorMessage) return;

  const target = document.querySelector(`[data-id=${button.dataset.target}]`);
  if (!target) return;

  let { currentPage } = button.dataset;
  let totalPages;
  const url = new URL(window.location);

  button.addEventListener('click', async () => {
    loadingIndicator.hidden = false;
    button.hidden = true;

    const nextPage = +currentPage + 1;
    url.searchParams.set('page', nextPage);

    try {
      const response = await fetch(url);

      if (response.ok) {
        currentPage = response.headers.get('X-Current-Page');
        totalPages = response.headers.get('X-Total-Pages');

        const html = await response.text();

        loadingIndicator.hidden = true;
        errorMessage.hidden = true;
        button.hidden = false;

        target.insertAdjacentHTML('beforeend', html);

        // On the last page the button removes itself
        if (currentPage === totalPages) {
          button.remove();
        }
      } else {
        throw new Error(response.statusText);
      }
    } catch {
      loadingIndicator.hidden = true;
      errorMessage.hidden = false;
      button.hidden = false;
    }
  });
});
