import ready from '../../util/ready';
import swal from '../../util/swal';
import I18n from '../../i18n/i18n';
import setScrollMarkers from '../../util/scroll-marker';
import toggleUuids from '../toggle-uuids';

ready(() => {
  toggleUuids('#toggle-section-uuids');

  const itemButtons = document.querySelectorAll('[data-id="new-item-button"]');

  if (itemButtons.length === 0) return;

  itemButtons.forEach((itemButton) => {
    itemButton.addEventListener('click', () => {
      // Save scroll position
      sessionStorage.setItem(
        '_scroll_position_item',
        window.scrollY.toString(),
      );
    });
  });

  const savedScrollPosition = sessionStorage.getItem('_scroll_position_item');
  if (savedScrollPosition) {
    window.scrollTo(0, parseInt(savedScrollPosition, 10));
    sessionStorage.removeItem('_scroll_position_item');
  }
  // Save scroll position after editing a section
  setScrollMarkers('.scroll_marker', '_scroll_position');

  document
    .querySelectorAll('[data-behavior="section-delete-forbidden-link"]')
    .forEach((sectionLink) => {
      sectionLink.addEventListener('click', (e) => {
        e.preventDefault();

        swal.fire({
          title: I18n.t('sections.admin.delete_forbidden'),
          text: I18n.t('sections.admin.delete_forbidden_text'),
          icon: 'error',
          showCancelButton: false,
          buttonsStyling: false,
          focusConfirm: true,
          heightAuto: false,
        });
      });
    });
});
