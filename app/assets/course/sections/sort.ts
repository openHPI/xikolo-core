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
    handleError(I18n.t('sections.admin.sort_error'), error);
  }
};

ready(() => {
  const sections = sortable('[data-behavior=sortable-sections]', {
    forcePlaceholderSize: true,
    placeholderClass: 'html5sortable-placeholder',
  });

  sections.forEach((section: HTMLElement) => {
    section.addEventListener('sortupdate', ((event: CustomEvent) => {
      const { url } = event.detail.item.dataset;
      const data = new FormData();
      // Add one to the index as sections_controller.rb#move expects a 1-based index
      data.append('position', event.detail.destination.elementIndex + 1);

      updateOrder(url, data);
    }) as EventListener);
  });
});
