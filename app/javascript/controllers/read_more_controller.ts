import { Controller } from '@hotwired/stimulus';

/**
 * Clamps a block of text and reveals a toggle button only when the text
 * actually overflows the clamp.
 *
 * With `collapseWhenHidden`, an expanded text collapses again once it is out
 * of sight, e.g. paged out of a carousel, so it no longer stretches the
 * carousel while off-screen.
 */
export default class extends Controller {
  static targets = ['content', 'button', 'moreLabel', 'lessLabel'];
  static classes = ['clamped'];
  static values = { collapseWhenHidden: Boolean };

  declare readonly contentTarget: HTMLElement;
  declare readonly buttonTarget: HTMLButtonElement;
  declare readonly moreLabelTarget: HTMLElement;
  declare readonly lessLabelTarget: HTMLElement;
  declare readonly clampedClass: string;
  declare readonly collapseWhenHiddenValue: boolean;

  private expanded = false;
  private observer?: ResizeObserver;
  private visibilityObserver?: IntersectionObserver;

  connect(): void {
    // Start collapsed, also when Turbo restores an expanded page from cache.
    this.render();

    this.observer = new ResizeObserver(() => this.updateButtonVisibility());
    this.observer.observe(this.contentTarget);

    if (this.collapseWhenHiddenValue) {
      this.visibilityObserver = new IntersectionObserver(([entry]) => {
        if (entry && !entry.isIntersecting) this.collapse();
      });
      this.visibilityObserver.observe(this.element);
    }
  }

  disconnect(): void {
    this.observer?.disconnect();
    this.visibilityObserver?.disconnect();
  }

  toggle(): void {
    this.expanded = !this.expanded;
    this.render();
  }

  private collapse(): void {
    if (!this.expanded) return;

    this.expanded = false;
    this.render();
  }

  private render(): void {
    this.contentTarget.classList.toggle(this.clampedClass, !this.expanded);
    this.buttonTarget.setAttribute('aria-expanded', String(this.expanded));
    this.moreLabelTarget.hidden = this.expanded;
    this.lessLabelTarget.hidden = !this.expanded;
  }

  private updateButtonVisibility(): void {
    // Once expanded, the button must stay to allow collapsing again.
    if (this.expanded) return;

    this.buttonTarget.hidden =
      this.contentTarget.scrollHeight <= this.contentTarget.clientHeight;
  }
}
