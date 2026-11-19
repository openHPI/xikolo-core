import { Controller } from '@hotwired/stimulus';
import xuiSwal from '../util/swal';

export default class extends Controller {
  static values = {
    options: Object,
  };

  declare optionsValue: object;

  connect() {
    xuiSwal.fire(this.optionsValue);
  }
}
