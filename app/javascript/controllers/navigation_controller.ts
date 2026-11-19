import { Controller } from '@hotwired/stimulus';

/**
 * Navigation actions (e.g. browser back).
 */
export default class extends Controller {
  back() {
    window.history.back();
  }
}
