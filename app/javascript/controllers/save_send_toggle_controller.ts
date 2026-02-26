import { Controller } from '@hotwired/stimulus';

/**
 * Toggles the "Save and send" button enabled/disabled based on the checkbox.
 */
export default class extends Controller {
  static targets = ['checkbox', 'button'];
  static classes = ['disabled'];

  declare checkboxTarget: HTMLInputElement;
  declare buttonTarget: HTMLButtonElement;
  declare disabledClass: string;

  connect() {
    this.toggle();
  }

  toggle() {
    const checked = this.checkboxTarget.checked;
    this.buttonTarget.disabled = !checked;
    this.buttonTarget.classList.toggle(this.disabledClass, !checked);
  }
}
