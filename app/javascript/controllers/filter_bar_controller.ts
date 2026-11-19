import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['toggle'];

  declare readonly toggleTarget: HTMLButtonElement;
  declare readonly hasToggleTarget: boolean;

  connect() {
    // Turbo can restore a cached page after following the Adjust link.
    if (window.location.hash === '#adjust-anchor') this.expand();
  }

  expand() {
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-expanded', 'true');
    }
  }
}
