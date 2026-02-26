import { Controller } from '@hotwired/stimulus';
import { showLoading } from '../util/loading';

export default class extends Controller {
  static targets = ['filterForm'];

  declare filterFormTarget: HTMLFormElement;

  submitFilter() {
    showLoading();
    this.filterFormTarget.submit();
  }

  cancelFudge(event: Event) {
    event.preventDefault();
    const btn = event.currentTarget as HTMLButtonElement;
    const fudge = btn.closest('.fudge') as HTMLElement;
    fudge.style.visibility = 'hidden';
  }

  showFudge(event: Event) {
    event.preventDefault();
    const btn = event.currentTarget as HTMLButtonElement;
    const submissionId = btn.dataset.submission;
    const pointsEl = document.getElementById(
      `points-${submissionId}`,
    ) as HTMLElement;
    const fudge = pointsEl.querySelector('.fudge') as HTMLElement;
    fudge.style.visibility = 'visible';
  }
}
