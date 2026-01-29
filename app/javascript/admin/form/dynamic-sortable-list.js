import TomSelect from 'tom-select';
import SortableInputs from '../../util/forms/sortable-inputs';
import ready from '../../util/ready';
import { tomSelectSettings } from '../../components/global/custom-select';

/*
 * Sortable list
 *
 * This script allows users to add values to a sortable list
 *
 * It is used for the DynamicSortableList ViewComponent.
 * It will assume that the following data-behavior attributes are present:
 *
 * 1. "sortable-list": This is the entry point for the script. There can be more
 *    than one on a page. Within this element, the following elements are nested:
 *
 * 2. "sortable-list__input" or "sortable-list__select": Users can add new list
 *    items either by typing them on an input field (*__input) or selecting them
 *    from a dropdown menu (*__select).
 *
 * 3. "sortable-list__btn-add": Button to save items from the input to the list.
 *    It is only required when using the *__input variant. User can also press 'enter'.
 *    Value must be truthy, and only unique items are added to the list.
 */

const addInputValueToList = (input, list) => {
  const { value } = input;
  if (value) {
    list.add(value, value);
    // Delete value from input after adding to list
    const inputContent = input;
    inputContent.value = '';
  }
};

const handleInputKeyDown = (event, input, list) => {
  if (event.key === 'Enter') {
    addInputValueToList(input, list);
    event.preventDefault();
  }
};

ready(() => {
  const sortableLists = document.querySelectorAll(
    '[data-behavior="sortable-list"]',
  );

  sortableLists.forEach((list) => {
    const sortableList = SortableInputs.createUniqueList(list);

    const sortableInput = list.querySelector(
      '[data-behavior="sortable-list__input"]',
    );

    const sortableSelect = list.querySelector(
      '[data-behavior="sortable-list__select"]',
    );

    if (!sortableInput && !sortableSelect) return;

    if (sortableInput) {
      sortableInput.addEventListener('keydown', (event) => {
        handleInputKeyDown(event, sortableInput, sortableList);
      });

      const addButton = list.querySelector(
        '[data-behavior="sortable-list__btn-add"]',
      );
      addButton.addEventListener('click', () => {
        addInputValueToList(sortableInput, sortableList);
      });
    } else if (sortableSelect) {
      new TomSelect(sortableSelect, {
        ...tomSelectSettings(sortableSelect),

        onItemAdd(value, item) {
          sortableList.add(value, item.textContent);
          this.clear();
        },
      });
    }
  });
});
