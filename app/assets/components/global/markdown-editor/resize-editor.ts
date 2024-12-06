import ToastUi from '@toast-ui/editor/types/index';

const hasScrollBar = (el: HTMLElement) => el.scrollHeight > el.clientHeight;
const toggleScrollbarModifier = (btn: HTMLElement, el: HTMLElement) => {
  if (el.clientHeight === 0) return;

  btn.classList.toggle(
    'markdown-editor__resize-btn--with-scrollbar',
    hasScrollBar(el),
  );
};

const setResizeBtn = (formInput: HTMLElement, editor: ToastUi) => {
  const resizeBtn = document.querySelector<HTMLElement>(
    `#${formInput.id}-resize`,
  );
  const editorTextArea = editor
    .getEditorElements()
    .mdEditor.querySelector<HTMLElement>('[contenteditable="true"]');

  if (!resizeBtn || !editorTextArea) return;

  const dropzone = document.querySelector<HTMLElement>(
    `.dropzone[data-textarea-id="#${formInput.id}"]`,
  );

  toggleScrollbarModifier(resizeBtn, editorTextArea);
  new MutationObserver(() => {
    toggleScrollbarModifier(resizeBtn, editorTextArea);
  }).observe(editorTextArea, {
    attributes: true,
  });

  resizeBtn.addEventListener('click', () => {
    const height = editor.getHeight();

    if (height && height === '300px') {
      editor.setHeight('auto');
      editor.setMinHeight('400px');
      resizeBtn.classList.add('markdown-editor__resize-btn--collapse');
      resizeBtn.title = I18n.t('components.markdown_editor.collapse');
      resizeBtn.ariaLabel = I18n.t('components.markdown_editor.collapse');
      if (dropzone) {
        // Set the height of the dropzone to match the height of the editor (plus the toolbar's height)
        dropzone.style.height = `${editor.getEditorElements().mdEditor.offsetHeight + 46}px`;
      }
    } else {
      editor.setHeight('300px');
      editor.setMinHeight('300px');
      resizeBtn.classList.remove('markdown-editor__resize-btn--collapse');
      resizeBtn.title = I18n.t('components.markdown_editor.expand');
      resizeBtn.ariaLabel = I18n.t('components.markdown_editor.expand');
      if (dropzone) {
        dropzone.style.height = '300px';
      }
    }
  });
};

export default setResizeBtn;
