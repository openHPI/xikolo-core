import { Controller } from '@hotwired/stimulus';
import type { SelectionEvent } from './player_controller';

export default class extends Controller<HTMLElement> {
  static targets = ['item'];

  declare readonly itemTargets: HTMLButtonElement[];

  private selectedIndex = 0;

  connect() {
    this.arrange(0);
  }

  previous() {
    this.browse(-1);
  }

  next() {
    this.browse(1);
  }

  selectClickedItem(event: Event) {
    const button = event.currentTarget as HTMLButtonElement;
    this.arrange(this.itemTargets.indexOf(button));
  }

  select(event: SelectionEvent) {
    this.arrange(event.detail.index);
  }

  restoreFocus() {
    this.itemTargets[this.selectedIndex]?.focus({ preventScroll: true });
  }

  private browse(direction: -1 | 1) {
    const count = this.itemTargets.length;
    if (count === 0) return;

    this.arrange((this.selectedIndex + direction + count) % count);
  }

  private arrange(selectedIndex: number) {
    this.selectedIndex = selectedIndex;
    const count = this.itemTargets.length;
    this.itemTargets.forEach((item, index) => {
      const depth = (index - selectedIndex + count) % count;
      item.hidden = depth >= 4;
      item.dataset.depth = String(depth);
    });
  }
}
