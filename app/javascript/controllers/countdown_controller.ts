import { Controller } from '@hotwired/stimulus';

/**
 * Countdown timer controller
 *
 * Updates whichever unit targets are rendered: days, hours, minutes and
 * seconds, and optional unit labels with singular/plural forms.
 *
 * Counts from the server's remaining time instead of an end date, so a wrong
 * clock on the user's device does not skew the countdown.
 */
export default class extends Controller {
  static values = {
    remainingSecs: Number,
    endsAt: Number,
    submitForm: String,
  };

  static targets = [
    'days',
    'hours',
    'minutes',
    'seconds',
    'daysLabel',
    'hoursLabel',
    'minutesLabel',
  ];

  declare remainingSecsValue: number;
  declare endsAtValue: number;
  declare hasEndsAtValue: boolean;
  declare submitFormValue: string;
  declare hasSubmitFormValue: boolean;
  declare hasDaysTarget: boolean;
  declare hasHoursTarget: boolean;
  declare hasSecondsTarget: boolean;
  declare hasDaysLabelTarget: boolean;
  declare hasHoursLabelTarget: boolean;
  declare hasMinutesLabelTarget: boolean;
  declare daysTarget: HTMLElement;
  declare hoursTarget: HTMLElement;
  declare minutesTarget: HTMLElement;
  declare secondsTarget: HTMLElement;
  declare daysLabelTarget: HTMLElement;
  declare hoursLabelTarget: HTMLElement;
  declare minutesLabelTarget: HTMLElement;

  private timer?: ReturnType<typeof setInterval>;
  private timerStarted = false;
  private pluralRules = new Intl.PluralRules(
    document.documentElement.lang || undefined,
  );

  connect() {
    // Stored as a data attribute so a page restored from Turbo's cache (e.g.
    // on browser back) continues the countdown instead of restarting it from
    // the server-rendered remaining time.
    if (!this.hasEndsAtValue) {
      this.endsAtValue = performance.now() + this.remainingSecsValue * 1000;
    }

    this.update();

    if (this.endsAtValue > performance.now()) {
      this.timerStarted = true;
      this.timer = setInterval(() => this.update(), 1000);
    }
  }

  disconnect() {
    clearInterval(this.timer);
  }

  private update() {
    const secs = Math.max(
      0,
      Math.ceil((this.endsAtValue - performance.now()) / 1000),
    );
    this.updateCountdownDisplay(secs);

    if (secs <= 0) {
      clearInterval(this.timer);
      if (!this.timerStarted) return;

      this.dispatch('done');
      if (this.hasSubmitFormValue) {
        document
          .querySelector<HTMLFormElement>(this.submitFormValue)
          ?.requestSubmit();
      }
    }
  }

  private updateCountdownDisplay(secs: number) {
    if (this.hasDaysTarget) {
      this.setCountdownValue(this.daysTarget, Math.floor(secs / 86400));
      this.setCountdownValue(
        this.hoursTarget,
        Math.floor((secs % 86400) / 3600),
      );
    } else if (this.hasHoursTarget) {
      this.setCountdownValue(this.hoursTarget, Math.floor(secs / 3600));
    }
    this.setCountdownValue(this.minutesTarget, Math.floor((secs % 3600) / 60));
    if (this.hasSecondsTarget) {
      this.setCountdownValue(this.secondsTarget, secs % 60);
    }

    if (this.hasDaysLabelTarget) {
      this.setUnitLabel(this.daysLabelTarget, Math.floor(secs / 86400));
    }
    if (this.hasHoursLabelTarget) {
      this.setUnitLabel(
        this.hoursLabelTarget,
        Math.floor((secs % 86400) / 3600),
      );
    }
    if (this.hasMinutesLabelTarget) {
      this.setUnitLabel(
        this.minutesLabelTarget,
        Math.floor((secs % 3600) / 60),
      );
    }
  }

  private setCountdownValue(target: HTMLElement, value: number) {
    target.style.setProperty('--x-value', String(value));
    // Days can need more than the default two digits.
    if (this.hasDaysTarget) {
      target.style.setProperty(
        '--x-digits',
        String(Math.max(String(value).length, 2)),
      );
    }
  }

  // Labels carry their singular and plural form in data-one / data-other.
  private setUnitLabel(label: HTMLElement, value: number) {
    const form = this.pluralRules.select(value) === 'one' ? 'one' : 'other';
    label.textContent = label.dataset[form] ?? label.textContent;
  }
}
