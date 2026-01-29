/**
 * When a specified element is clicked, the utility stores the current vertical scroll position
 * in the browser's session storage. After a page reload, the page retrieves the stored position
 * from session storage and maintains the scroll position. A common use case is to bring the user
 * to the same window position after a form submission.
 *
 * @param {string} targetSelector - The selector of the element. Clicking this element will store the scroll position.
 * @param {string} storageItem - The name of the storage item used for storing the scroll position.
 */

const setScrollMarkers = (targetSelector: string, storageItem: string) => {
  document.querySelectorAll(targetSelector).forEach((mark) => {
    mark.addEventListener('click', () => {
      sessionStorage.setItem(storageItem, window.scrollY.toString());
    });
  });

  const scrollPosition = sessionStorage.getItem(storageItem);

  if (scrollPosition !== null) {
    window.scrollTo(0, parseInt(scrollPosition, 10));
    sessionStorage.removeItem(storageItem);
  }
};

export default setScrollMarkers;
