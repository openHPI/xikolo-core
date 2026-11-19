import { Controller } from '@hotwired/stimulus';

/**
 * Shows the message of a daisyUI toast for a few seconds.
 *
 * Keep the toast container (with role="status") in the DOM, so screen readers
 * announce the message when it appears.
 */
export default class extends Controller {
  static targets = ['message'];
  static values = { duration: { type: Number, default: 5000 } };

  declare readonly messageTarget: HTMLElement;
  declare readonly durationValue: number;

  private timeout?: number;

  connect(): void {
    // Turbo may restore the page from cache with the message still visible.
    this.messageTarget.hidden = true;
  }

  disconnect(): void {
    window.clearTimeout(this.timeout);
  }

  show(): void {
    window.clearTimeout(this.timeout);
    this.messageTarget.hidden = false;
    this.timeout = window.setTimeout(() => {
      this.messageTarget.hidden = true;
    }, this.durationValue);
  }
}
