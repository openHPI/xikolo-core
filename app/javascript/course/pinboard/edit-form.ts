import { initializeTomSelect } from '../../components/global/custom-select';
import initMarkdownEditorOnSelector from '../../util/markdown-editor';
import mdupload from '../../util/forms/mdupload';
import upload from '../../util/forms/upload';

document.addEventListener('turbo:frame-load', (event) => {
  const frame = event.target as HTMLElement;
  if (!frame.matches('[data-pinboard-edit-form]')) return;

  initializeTomSelect(frame);
  void initMarkdownEditorOnSelector(frame);
  upload.scan(frame);
  mdupload.scan(frame);
});

document.addEventListener('click', (event) => {
  const cancelButton = (event.target as Element | null)?.closest(
    '[data-pinboard-edit-cancel]',
  );
  if (!cancelButton) return;

  const frame = cancelButton.closest<HTMLElement>('[data-pinboard-edit-form]');
  if (!frame) return;

  event.preventDefault();
  frame.innerHTML = '';
});
