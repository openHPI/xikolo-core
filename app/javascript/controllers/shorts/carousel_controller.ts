import { Controller } from '@hotwired/stimulus';
import type { SelectionEvent } from './player_controller';

// Number of item sets rendered
// (real set + one clone set on each side)
const SET_COUNT = 3;

export default class extends Controller<HTMLElement> {
  static targets = ['carousel', 'navButton', 'item', 'zoomItem'];

  static values = {
    infinite: Boolean,
  };

  declare readonly infiniteValue: boolean;
  declare readonly carouselTarget: HTMLElement;
  declare readonly navButtonTargets: HTMLElement[];
  declare readonly itemTargets: HTMLElement[];
  declare readonly zoomItemTargets: HTMLElement[];

  private resizeObserver?: ResizeObserver;
  // Which item the carousel is centered on: an index into itemTargets
  // (clones included), driven by the intersection observer and teleport.
  private centeredItemIndex = 0;
  private centerObserver?: IntersectionObserver;

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.toggleNavButtons());
    this.resizeObserver.observe(this.carouselTarget);

    if (this.infiniteValue) {
      this.centerFirstRealItem();

      this.centerObserver = new IntersectionObserver(
        (entries) => this.handleCenterIntersections(entries),
        {
          root: this.carouselTarget,
          // Shrinks the observed area to a thin vertical band across the
          // middle, so only the item(s) currently centered intersect it.
          rootMargin: '0px -45% 0px -45%',
        },
      );
      this.zoomItemTargets.forEach((item) =>
        this.centerObserver?.observe(item),
      );

      this.carouselTarget.addEventListener('scrollend', this.handleScrollEnd);
    }
  }

  disconnect() {
    this.carouselTarget.removeEventListener('scrollend', this.handleScrollEnd);
    this.resizeObserver?.disconnect();
    this.centerObserver?.disconnect();
  }

  scrollBack() {
    this.scrollByOneItem(-1);
  }

  scrollForward() {
    this.scrollByOneItem(1);
  }

  centerClickedItem(event: Event) {
    const button = event.currentTarget as HTMLButtonElement;
    const index = this.itemTargets.indexOf(button);

    this.centeredItemIndex = index;
    this.centerItem(index);
  }

  centerPlayingItem(event: SelectionEvent) {
    this.centerItem(this.firstRealIndex + event.detail.index, 'instant');
  }

  private handleCenterIntersections(entries: IntersectionObserverEntry[]) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;

      this.centeredItemIndex = this.zoomItemTargets.indexOf(
        entry.target as HTMLElement,
      );
      this.applyZoomTiers(this.centeredItemIndex);
    });
  }

  // Zooms the centered item the most, its immediate neighbors slightly
  // less, and resets every other item back to its base size.
  private applyZoomTiers(centeredItemIndex: number) {
    this.zoomItemTargets.forEach((item, index) => {
      const isCentered = index === centeredItemIndex;
      const isNextToCentered = Math.abs(index - centeredItemIndex) === 1;

      item.classList.toggle('scale-110', isCentered);
      item.classList.toggle('scale-105', isNextToCentered);
    });
  }

  private toggleNavButtons() {
    const carousel = this.carouselTarget;
    const scrollable = carousel.scrollWidth > carousel.clientWidth + 1;

    this.navButtonTargets.forEach((button) => {
      button.hidden = !scrollable;
    });
  }

  private centerFirstRealItem() {
    this.centerItem(this.firstRealIndex, 'instant');
  }

  // Number of real videos, ignoring the clone sets
  private get realItemCount() {
    return this.infiniteValue
      ? this.itemTargets.length / SET_COUNT
      : this.itemTargets.length;
  }

  private get firstRealIndex() {
    // Clones are split evenly, so half of them sit before the real set.
    return this.infiniteValue
      ? (this.itemTargets.length - this.realItemCount) / 2
      : 0;
  }

  // Folds any item index onto its matching element in the real set
  private realItemIndexOf(index: number) {
    const count = this.realItemCount;
    const position = (((index - this.firstRealIndex) % count) + count) % count;
    return this.firstRealIndex + position;
  }

  // All items are equally apart
  private get distanceBetweenItems() {
    return this.itemTargets[1]!.offsetLeft - this.itemTargets[0]!.offsetLeft;
  }

  // Detects when scrolling has stopped, so the teleport never
  // interrupts an ongoing scroll or touch gesture.
  private handleScrollEnd = () => {
    this.teleportToRealSet();
  };

  // Once the centered item lies in a clone set, teleports the scroll
  // position by one whole set width back into the real set
  private teleportToRealSet() {
    if (!this.infiniteValue) return;

    const realIndex = this.realItemIndexOf(this.centeredItemIndex);
    if (realIndex === this.centeredItemIndex) return; // already in the real set

    this.centeredItemIndex = realIndex;
    this.centerItem(realIndex, 'instant');

    // Teleporting must go unnoticed. We don't want another zoom animation when
    // landing on the real set, so applyZoomTiers runs with transitions disabled.
    this.zoomItemTargets.forEach((item) => {
      item.classList.add('transition-none');
    });
    this.applyZoomTiers(this.centeredItemIndex);

    // Reading a layout property forces a browser reflow, recording the new
    // scale classes while transitions are still off.
    void this.carouselTarget.offsetWidth;

    this.zoomItemTargets.forEach((item) => {
      item.classList.remove('transition-none');
    });
  }

  private scrollByOneItem(direction: -1 | 1) {
    this.teleportToRealSet();

    this.carouselTarget.scrollBy({
      left: direction * this.distanceBetweenItems,
      behavior: this.scrollBehavior,
    });
  }

  // Honors the user's reduced-motion preference, jumping instantly
  // instead of animating the scroll when it's set.
  private get scrollBehavior(): ScrollBehavior {
    const prefersReducedMotion = window.matchMedia(
      '(prefers-reduced-motion: reduce)',
    ).matches;

    return prefersReducedMotion ? 'instant' : 'smooth';
  }

  // Scrolls the carousel so the item at the given index is centered;
  private centerItem(index: number, behavior?: ScrollBehavior) {
    const carousel = this.carouselTarget;
    const item = this.itemTargets[index]!;

    carousel.scrollTo({
      left:
        item.offsetLeft -
        this.itemTargets[0]!.offsetLeft -
        (carousel.clientWidth - item.offsetWidth) / 2,
      behavior: behavior ?? this.scrollBehavior,
    });
  }
}
