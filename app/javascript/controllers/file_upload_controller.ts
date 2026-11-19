import { Controller } from '@hotwired/stimulus';

type ItemState = 'selected' | 'uploading' | 'complete' | 'failed';

export default class extends Controller<HTMLElement> {
  static targets = ['input', 'list', 'items', 'itemTemplate'];

  static values = {
    uploadingText: String,
    completeText: String,
    failedText: String,
  };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly listTarget: HTMLElement;
  declare readonly itemsTarget: HTMLUListElement;
  declare readonly itemTemplateTarget: HTMLTemplateElement;
  declare readonly uploadingTextValue: string;
  declare readonly completeTextValue: string;
  declare readonly failedTextValue: string;

  // The file dialog overwrites `input.files` on every new pick, so what has been
  // selected so far is saved here and merged back into the input.
  private selected: File[] = [];

  fileSelected() {
    this.add(this.files);
  }

  remove(event: Event) {
    const item = (event.target as HTMLElement).closest('li');
    if (!item) return;

    const index = Array.from(this.itemsTarget.children).indexOf(item);
    this.setSelection(
      this.selected.filter((_, position) => position !== index),
    );

    item.remove();
    this.syncListVisibility();
  }

  // Without this the browser cancels the drop and opens the file instead.
  dragOver(event: DragEvent) {
    event.preventDefault();
  }

  drop(event: DragEvent) {
    event.preventDefault();

    const dropped = Array.from(event.dataTransfer?.files ?? []).filter((file) =>
      this.accepts(file),
    );
    if (dropped.length === 0) return;

    this.add(dropped);
  }

  start(event: Event) {
    const item = this.itemFor(this.detail(event).file);
    if (item) this.setState(item, 'uploading', 0);
  }

  update(event: Event) {
    const { file, progress } = this.detail(event);
    const item = this.itemFor(file);
    if (!item) return;

    this.setState(item, 'uploading', progress ?? 0);
  }

  error(event: Event) {
    // Suppresses Active Storage's default `alert` — the item reports the error.
    event.preventDefault();

    const item = this.itemFor(this.detail(event).file);
    if (item) this.setState(item, 'failed');
  }

  handleEnd(event: Event) {
    const item = this.itemFor(this.detail(event).file);
    // `direct-upload:end` also fires after a failure, which must keep its state.
    if (item && item.dataset.state !== 'failed') {
      this.setState(item, 'complete');
    }
  }

  private get files() {
    return Array.from(this.inputTarget.files ?? []);
  }

  // The file dialog applies `accept` itself, but files arriving through a drop
  // bypass it, so they are matched here to keep unsupported ones out.
  private accepts(file: File) {
    const accept = this.inputTarget.accept.trim();
    if (accept === '') return true;

    const type = file.type.toLowerCase();
    const name = file.name.toLowerCase();

    return accept.split(',').some((entry) => {
      const rule = entry.trim().toLowerCase();
      if (rule === '') return false;
      if (rule.startsWith('.')) return name.endsWith(rule);
      if (rule.endsWith('/*')) return type.startsWith(rule.slice(0, -1));
      return type === rule;
    });
  }

  // A single-file input keeps only the latest pick, a multiple one
  // accumulates every pick made so far.
  private add(files: File[]) {
    this.setSelection(
      this.inputTarget.multiple
        ? [...this.selected, ...files]
        : files.slice(0, 1),
    );
    this.renderItems();
  }

  private setSelection(files: File[]) {
    this.syncInputField(files);
    this.selected = files;
  }

  // `input.files` only accepts a FileList, which has no constructor —
  // DataTransfer is the one way to build one.
  private syncInputField(files: File[]) {
    const transfer = new DataTransfer();
    files.forEach((file) => transfer.items.add(file));
    this.inputTarget.files = transfer.files;
  }

  private renderItems() {
    this.itemsTarget.replaceChildren(
      ...this.selected.map((file) => this.buildItem(file)),
    );
    this.syncListVisibility();
  }

  private buildItem(file: File) {
    const item = this.itemTemplateTarget.content.firstElementChild!.cloneNode(
      true,
    ) as HTMLLIElement;

    item.dataset.state = 'selected';
    item.dataset.fileName = file.name;
    item.dataset.fileSize = String(file.size);
    item.dataset.fileLastModified = String(file.lastModified);
    this.part(item, 'name').textContent = file.name;

    return item;
  }

  // Active Storage's upload events carry a File with nothing pointing back at
  // the item built for it in the list, so the two are matched on the file's
  // name, size and modification time.
  private itemFor(file: File) {
    return Array.from(this.itemsTarget.children).find(
      (item): item is HTMLLIElement =>
        item instanceof HTMLLIElement &&
        item.dataset.fileName === file.name &&
        item.dataset.fileSize === String(file.size) &&
        item.dataset.fileLastModified === String(file.lastModified),
    );
  }

  private setState(item: HTMLLIElement, state: ItemState, progress = 0) {
    item.dataset.state = state;

    const status = this.part(item, 'status');
    const statusText = this.part(item, 'statusText');
    const bar = this.part(item, 'bar') as HTMLProgressElement;

    status.hidden = false;
    status.classList.toggle('text-accent', state === 'uploading');
    status.classList.toggle('text-success-content', state === 'complete');
    status.classList.toggle('text-error', state === 'failed');

    this.part(item, 'completeIcon').hidden = state !== 'complete';
    this.part(item, 'failedIcon').hidden = state !== 'failed';

    // Do not show the remove button while uploading or after completion.
    // Show it before submitting and on failure.
    this.part(item, 'remove').hidden =
      state === 'uploading' || state === 'complete';

    bar.hidden = state !== 'uploading';
    bar.value = progress;

    statusText.textContent = {
      selected: '',
      uploading: this.uploadingTextValue.replace(
        '%{progress}',
        String(Math.round(progress)),
      ),
      complete: this.completeTextValue,
      failed: this.failedTextValue,
    }[state];
  }

  private syncListVisibility() {
    this.listTarget.hidden = this.itemsTarget.childElementCount === 0;
  }

  private detail(event: Event) {
    return (event as CustomEvent<{ file: File; progress?: number }>).detail;
  }

  private part(item: HTMLLIElement, name: string) {
    return item.querySelector<HTMLElement>(
      `[data-file-upload-part="${name}"]`,
    )!;
  }
}
