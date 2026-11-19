import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { selector: String };

  declare selectorValue: string;
  declare hasSelectorValue: boolean;

  // Without a selector, hides the controller's own element.
  hide() {
    const target = (
      this.hasSelectorValue
        ? this.element.closest(this.selectorValue)
        : this.element
    ) as HTMLElement | null;
    if (target) target.hidden = true;
  }
}
