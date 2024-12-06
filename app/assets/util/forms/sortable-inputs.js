import sortable from 'html5sortable/dist/html5sortable.es';

/**
 * A component for sorting a list of (hidden) form inputs.
 *
 * The provided DOM element must contain an <ol> container and an HTML
 * <template> that is used to add new elements to the list, which will be
 * sortable via drag-and-drop.
 *
 * The template:
 * - MUST contain a hidden <input> tag,
 * - CAN contain an element matching [data-target=label], which will be filled
 *   with a label for the user,
 * - CAN contain a clickable element matching [data-behavior=delete], which
 *   will trigger removal of an item from a list, and
 * - can contain arbitrary DOM elements for styling and additional behavior.
 *
 * Each list element generated from the template will be automatically wrapped
 * inside a <li> tag and added to the ordered list.
 */
export const REMOVE_INPUT_EVENT = 'remove-input-event';

export default class SortableInputs {
  constructor(properties) {
    const { element, unique } = properties;
    this.element = element;
    this.unique = unique;

    this.sortable = sortable(this.element.querySelector('ol'), {
      forcePlaceholderSize: true,
    });

    // collect all inputs as array for iterating
    this.values = [];
    const inputs = this.element.querySelectorAll('input[type=hidden]');
    let i;

    if (inputs) {
      for (i = 0; i < inputs.length; i += 1) {
        this.values.push(inputs[i].value);
      }
    }

    this.element.addEventListener('click', this);
  }

  static createUniqueList(element) {
    return new SortableInputs({ element, unique: true });
  }

  static create(element) {
    return new SortableInputs({ element, unique: false });
  }

  static delete(childNode) {
    childNode.parentNode.removeChild(childNode);
  }

  getAllValues() {
    return this.values;
  }

  /**
   * Programmatically add a new item to the list.
   *
   * @param {String} value The identifier to be used for the hidden input
   * @param {String} label The friendly name to be rendered to the user
   */
  add(value, label) {
    if ((this.unique && !this.values.includes(value)) || !this.unique) {
      const newItem = this.element
        .querySelector('template')
        .content.cloneNode(true);
      newItem.querySelector('[data-target=label]').textContent = label;
      newItem.querySelector('input[type=hidden]').value = value;
      const newListItem = document.createElement('li');
      newListItem.appendChild(newItem);
      this.element.querySelector('ol').appendChild(newListItem);
      this.values.push(value);

      this.reload();
    }
  }

  reload() {
    sortable(this.sortable);
  }

  handleEvent(event) {
    if (event.target.matches('[data-behavior=delete]')) {
      const childNode = event.target.closest('li');
      const nodeValue = childNode.querySelector('input[type=hidden]').value;
      this.values = this.values.filter((value) => value !== nodeValue);
      const removeInputEvent = new CustomEvent(REMOVE_INPUT_EVENT, {
        detail: nodeValue,
      });
      this.element.dispatchEvent(removeInputEvent);
      this.constructor.delete(childNode);
      event.preventDefault();
    }
  }
}
