import { Controller } from '@hotwired/stimulus';

/**
 * Shows the guardian-consent disclaimer on the registration form while the
 * entered birthdate makes the user underage. Its inputs are disabled while
 * hidden, so nothing is submitted for users of age.
 *
 * The privacy consent notice is the inverse: underage users consent via their
 * guardian, so it is only shown to users of age.
 */
export default class extends Controller {
  static targets = ['birthdate', 'disclaimer', 'privacyAgreement'];
  static values = { ageOfConsent: Number };

  declare readonly birthdateTarget: HTMLInputElement;
  declare readonly hasBirthdateTarget: boolean;
  declare readonly disclaimerTarget: HTMLElement;
  declare readonly hasDisclaimerTarget: boolean;
  declare readonly privacyAgreementTarget: HTMLElement;
  declare readonly hasPrivacyAgreementTarget: boolean;
  declare readonly ageOfConsentValue: number;

  connect() {
    this.update();
  }

  update() {
    if (!this.hasBirthdateTarget) return;

    const underage = this.underage();

    if (this.hasDisclaimerTarget) {
      this.disclaimerTarget.hidden = !underage;
      // Both the checkbox and the hidden field Rails pairs it with, so that an
      // unticked box submits `false` rather than nothing at all.
      this.disclaimerTarget.querySelectorAll('input').forEach((input) => {
        input.disabled = !underage;
      });
    }

    if (this.hasPrivacyAgreementTarget) {
      this.privacyAgreementTarget.hidden = underage;
    }
  }

  private underage(): boolean {
    const birthdate = this.birthdateTarget.value;
    if (!birthdate) return false;

    const cutoff = new Date();
    cutoff.setFullYear(cutoff.getFullYear() - this.ageOfConsentValue);
    return new Date(birthdate) > cutoff;
  }
}
