import sortable from 'html5sortable/dist/html5sortable.es';
import fetch from '../../util/fetch';
import ready from '../../util/ready';
import handleError from '../../util/error';
import I18n from '../../i18n/i18n';

const updateOrder = async (url: string, data: FormData) => {
  try {
    await fetch(url, {
      method: 'POST',
      body: data,
    });
  } catch (error) {
    handleError(I18n.t('items.errors.update'), error);
  }
};

ready(() => {
  const items = sortable('[data-behavior=sortable-items]', {
    forcePlaceholderSize: true,
    placeholderClass: 'html5sortable-placeholder',
    acceptFrom: '[data-behavior=sortable-items]',
    handle: '[data-behavior=item-handle]',
  });

  items.forEach((item: HTMLElement) => {
    item.addEventListener('sortupdate', ((event: CustomEvent) => {
      const { url } = event.detail.item.dataset;
      const data = new FormData();
      const newPosition = event.detail.destination.elementIndex;

      data.append('position', newPosition);

      const sortableItems = event.detail.destination.items;

      const rightSibling = sortableItems[newPosition + 1];
      const leftSibling = sortableItems[newPosition - 1];

      if (rightSibling) {
        data.append('right_sibling', rightSibling.dataset.nodeId);
      }

      if (leftSibling) {
        data.append('left_sibling', leftSibling.dataset.nodeId);
      }

      const originSectionId =
        event.detail.origin.container.parentElement.dataset.id;
      const destinationSectionId =
        event.detail.destination.container.parentElement.dataset.id;

      // The item is moved to another section
      if (originSectionId !== destinationSectionId) {
        const destinationSectionNodeId =
          event.detail.destination.container.parentElement.dataset.nodeId;
        data.append('new_section_id', destinationSectionId);
        data.append('new_section_node_id', destinationSectionNodeId);
      }

      updateOrder(url, data);
    }) as EventListener);
  });
});
