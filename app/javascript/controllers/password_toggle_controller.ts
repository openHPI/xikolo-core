import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'icon'];
  static values = {
    showLabel: String,
    hideLabel: String,
  };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly iconTargets: HTMLElement[];
  declare readonly showLabelValue: string;
  declare readonly hideLabelValue: string;

  toggle(event: Event): void {
    const isPassword = this.inputTarget.type === 'password';
    const button = event.currentTarget as HTMLButtonElement;
    this.inputTarget.type = isPassword ? 'text' : 'password';
    this.iconTargets.forEach((icon) => icon.toggleAttribute('hidden'));
    button.setAttribute(
      'aria-label',
      isPassword ? this.hideLabelValue : this.showLabelValue,
    );
    button.setAttribute('aria-pressed', String(isPassword));
  }
}
