import { Controller } from '@hotwired/stimulus';

/**
 * Pages a horizontally scrolling track with previous/next buttons. The number
 * of items per page is derived from the rendered item widths, so it follows
 * the CSS breakpoints.
 */
export default class extends Controller {
  static targets = ['track', 'item', 'previous', 'next'];

  declare readonly trackTarget: HTMLElement;
  declare readonly itemTargets: HTMLElement[];
  declare readonly previousTarget: HTMLButtonElement;
  declare readonly nextTarget: HTMLButtonElement;

  private observer?: ResizeObserver;

  connect(): void {
    this.observer = new ResizeObserver(() => this.update());
    this.observer.observe(this.trackTarget);
  }

  disconnect(): void {
    this.observer?.disconnect();
  }

  previous(): void {
    this.scrollToPage(this.currentPage - 1);
  }

  next(): void {
    this.scrollToPage(this.currentPage + 1);
  }

  update(): void {
    const singlePage = this.pageCount <= 1;

    this.previousTarget.hidden = singlePage;
    this.nextTarget.hidden = singlePage;
    this.updateButtons();
  }

  updateButtons(): void {
    this.previousTarget.disabled = this.trackTarget.scrollLeft <= 1;
    this.nextTarget.disabled = this.atEnd;
  }

  // Distance between the start of two neighbouring items
  private get itemStep(): number {
    const gap = parseFloat(getComputedStyle(this.trackTarget).columnGap) || 0;
    return this.itemTargets[0]!.offsetWidth + gap;
  }

  private get itemsPerPage(): number {
    const visible = (this.trackTarget.clientWidth + 1) / this.itemStep;
    return Math.max(1, Math.round(visible));
  }

  private get pageCount(): number {
    return Math.ceil(this.itemTargets.length / this.itemsPerPage);
  }

  private get atEnd(): boolean {
    const track = this.trackTarget;
    return track.scrollLeft + track.clientWidth >= track.scrollWidth - 1;
  }

  // The page the first visible item belongs to. Rounds down so that after a
  // partial manual scroll, "previous" still goes back to the start of the page.
  private get currentPage(): number {
    if (this.atEnd) return this.pageCount - 1;

    const firstVisibleItem = Math.round(
      this.trackTarget.scrollLeft / this.itemStep,
    );
    return Math.floor(firstVisibleItem / this.itemsPerPage);
  }

  private scrollToPage(page: number): void {
    const lastPage = this.pageCount - 1;
    const target = Math.min(Math.max(page, 0), lastPage);
    const item = this.itemTargets[target * this.itemsPerPage]!;

    this.trackTarget.scrollTo({
      left: item.offsetLeft - this.itemTargets[0]!.offsetLeft,
      behavior: this.scrollBehavior,
    });
  }

  // Jumps instead of animating when the user prefers reduced motion
  private get scrollBehavior(): ScrollBehavior {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
      ? 'instant'
      : 'smooth';
  }
}
