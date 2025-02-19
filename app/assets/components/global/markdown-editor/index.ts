/**
 * ToastUI editor initializer
 *
 * This script transforms form textarea fields into markdown editors.
 * For more details on how to use it, please refer to the preview template
 * (app/components/util/markdown_input/markdown_input.html.slim).
 *
 * This script also works with the simple form input "MarkdownInput"
 * (app/inputs/markdown_input.rb).
 *
 */

// Import locales
import '@toast-ui/editor/dist/i18n/de-de';
import '@toast-ui/editor/dist/i18n/es-es';
import '@toast-ui/editor/dist/i18n/fr-fr';
import '@toast-ui/editor/dist/i18n/uk-ua';

import ToastUi from '@toast-ui/editor';
import ToastUiType from '@toast-ui/editor/types/index';
import { Pos } from '@toast-ui/editor/types/toastmark';

import ready from '../../../util/ready';
import I18n from '../../../i18n/i18n';
import parseMarkdownToHTML from './html-parser';
import setResizeBtn from './resize-editor';

const isImage = (url: string) =>
  url.toLowerCase().match(/\.(jpeg|jpg|gif|png|apng|svg|avif|webp)$/) != null;

const BACKTICK = 192;
// These counters can be global. Scoping them to each editor becomes redundant
// since they are reset to this state when switching editors.
// Read more: https://github.com/openHPI/codeocean/pull/2242#discussion_r1576617432
let backtickPressedCount = 0;
let justInsertedCodeBlock = false;

const deleteSelection = (editor: ToastUiType, count: number) => {
  // The backtick is a so-called dead key, which is waiting for further input to be combined with.
  // For example a backtick and the letter a are combined to à.
  // When we remove a selection ending with a backtick, we want to clear the keyboard buffer, too.
  // This ensures that typing a regular character a after this operation is not combined into à, but just inserted as a.
  // This solution is taken from https://stackoverflow.com/a/72634132.
  editor.blur();
  setTimeout(() => editor.focus());
  // Get current position
  const selectionRange = editor.getSelection();
  // Replace the previous `count` characters with an empty string.
  // We use a replace function (rather than delete) to avoid issues with line breaks in ToastUi.
  // Otherwise, a line break following the cursor position might still be displayed normally,
  // but could be removed erroneously from the internal editor state.
  // If this happens, code blocks ending with \n``` are not recognized correctly.
  editor.replaceSelection(
    '',
    [(selectionRange[0] as Pos)[0], (selectionRange[0] as Pos)[1] - count],
    [(selectionRange[1] as Pos)[0], (selectionRange[1] as Pos)[1]],
  );
};
const resetCount = (withBlock = false) => {
  backtickPressedCount = 0;
  justInsertedCodeBlock = withBlock;
};

export default function initializeMarkdownEditor(
  scope: Document | HTMLElement = document,
) {
  const editors = scope.querySelectorAll(
    '[data-behavior="markdown-editor-wrapper"]',
  );

  editors.forEach((wrapper) => {
    const editor = wrapper.querySelector<HTMLElement>(
      '[data-behavior="markdown-editor-widget"]',
    );
    const formInput = wrapper.querySelector<HTMLInputElement>(
      '[data-behavior="markdown-form-input"]',
    );

    if (!editor || !formInput) return;

    let preview = editor.querySelector<HTMLElement>(
      '.toastui-editor-md-preview .toastui-editor-contents',
    );

    let uploadUrl = '';
    const urlMapping = wrapper.querySelector<HTMLInputElement>(
      `${formInput.dataset.urlMapping}`,
    );
    const uploadedFilesMapping = urlMapping ? JSON.parse(urlMapping.value) : {};

    const errorElement = scope.querySelector<HTMLElement>(
      `#${formInput.id}-error`,
    );

    const toastEditor = new ToastUi({
      el: editor,
      initialValue: formInput.value,
      placeholder: formInput.placeholder,
      previewHighlight: false,
      height: '300px',
      autofocus: false,
      usageStatistics: false,
      language: I18n.locale,
      toolbarItems: [
        ['heading', 'bold', 'italic'],
        ['link', 'code', 'codeblock', 'ul', 'ol', 'quote', 'table'],
      ],
      customHTMLRenderer: {
        // We are not using the toastUI preview although it is still being built in the background.
        // To avoid unnecessary image requests we disable toastUI preview image rendering.
        image: () => null,
      },
      hideModeSwitch: true, // Hide WYSIWYG mode
      initialEditType: 'markdown',
      events: {
        change: () => {
          // Keep <textarea> in sync
          const content = toastEditor.getMarkdown();
          formInput.value = content;
          // Keep preview in sync (with markdown-it parser)
          preview ||= editor.querySelector<HTMLElement>(
            '.toastui-editor-md-preview .toastui-editor-contents',
          );

          if (editor.dataset.imageUpload === 'true') {
            const dropzone = wrapper.querySelector<HTMLElement>(
              `[data-textarea-id='#${formInput.id}']`,
            );
            uploadUrl ||= dropzone!.dataset.mdupload as string;
          }

          preview!.innerHTML = parseMarkdownToHTML(
            content,
            uploadUrl,
            uploadedFilesMapping,
          );

          // Reset error message
          errorElement!.textContent = '';
        },
        // Fix ToastUI editor bug preventing manual codeblock insertion:
        // Manually inserting a codeblock adding three backticks and hitting enter
        // is not functioning in the ToastUI editor due to an existing bug in the library.
        // Therefore, this `keyup` handler implements a workaround to address the issue.
        keyup: (_, event) => {
          // Although the use of keyCode seems to be deprecated, the suggested alternatives (key or code)
          // work inconsistently across browsers. Using keyCode works flawless for now.
          // Read more: https://github.com/openHPI/codeocean/pull/2242#discussion_r1576675620
          if (event.keyCode === BACKTICK) {
            backtickPressedCount += 1;
            if (backtickPressedCount === 2) {
              // Remove the last two backticks and insert a code block
              // The order of operations is important here: Inserting the code block first and then removing
              // some backticks won't work, since this would infer with the internal ToastUi editor state.
              // With the current solution, we don't mingle with the code block inserted by ToastUi at all.
              deleteSelection(toastEditor, 2);
              toastEditor.exec('codeBlock');
              resetCount(true);
            }
          } else if (backtickPressedCount === 1 && justInsertedCodeBlock) {
            // We want to improve the usage of our code block fix with the following mechanism.
            // Usually, three backticks are required to start a code block.
            // However, with our workaround only two backticks are required.
            // Out of habit, however, users might still enter three backticks at once,
            // not noticing that the code block was already inserted after the second one.
            // Thus, we remove one additional backtick entered after starting a code block through our fix.
            deleteSelection(toastEditor, 1);
            resetCount();
          } else {
            // If any other key is pressed, reset the count
            resetCount();
          }
        },
      },
    });

    setResizeBtn(formInput, toastEditor);

    // Prevent user from drag'n'dropping images in the editor
    toastEditor.removeHook('addImageBlobHook');

    // Custom event to programmatically insert a link to cursor position
    // Fired from mdupload.js
    editor.addEventListener('markdownEditor::addLink', ((e: CustomEvent) => {
      if (e.detail) {
        if (isImage(e.detail.url)) {
          toastEditor.exec('addImage', {
            altText: 'Insert image description',
            imageUrl: e.detail.url,
          });
        } else {
          toastEditor.exec('addLink', {
            linkText: e.detail.name,
            linkUrl: e.detail.url,
          });
        }
      }
    }) as EventListener);

    // Delegate invalid error message from form input to our error element
    if (errorElement) {
      formInput.addEventListener('invalid', (e) => {
        const target = e.target as HTMLInputElement;
        errorElement.textContent = target.validationMessage;
      });
    }

    // Delegate focus from form input to toast ui editor
    formInput.addEventListener('focus', () => {
      toastEditor.focus();
    });

    // Override toastUI preview with HTML parsed by markdown-it
    // to avoid bugs in their parser
    // Referenced links: https://github.com/nhn/tui.editor/issues/1635
    // Softbreak: https://github.com/nhn/tui.editor/issues/485
    const content = toastEditor.getMarkdown();
    preview ||= editor.querySelector<HTMLElement>(
      '.toastui-editor-md-preview .toastui-editor-contents',
    );

    // Set parsing rule to use right urls for previewing images
    if (editor.dataset.imageUpload === 'true') {
      const dropzone = wrapper.querySelector<HTMLElement>(
        `[data-textarea-id='#${formInput.id}']`,
      );
      uploadUrl ||= dropzone!.dataset.mdupload as string;
    }
    preview!.innerHTML = parseMarkdownToHTML(
      content,
      uploadUrl,
      uploadedFilesMapping,
    );
    // We can save some events since we don't use the toastUI preview
    toastEditor.eventEmitter.removeEventHandler('updatePreview');
    toastEditor.eventEmitter.removeEventHandler('beforePreviewRender');
    toastEditor.eventEmitter.removeEventHandler('scroll');
  });
}

ready(() => {
  initializeMarkdownEditor();
});
