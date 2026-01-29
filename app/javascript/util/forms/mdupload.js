/**
 * This module provides a script to attach JS to the markdown input
 * See app/inputs/markdown_input.rb
 */

import Dropzone from 'dropzone';
import ready from '../ready';
import sanitize from '../sanitize';

Dropzone.autoDiscover = false;

const initMdUpload = (el) => {
  const elZone = el.querySelector('.xui-mdupload-zone');

  if (!elZone || elZone.dropzone != null) {
    return;
  }

  const s3 = JSON.parse(el.dataset.s3);
  const url = el.dataset.mdupload;

  // (pre)process passed arguments:
  const s3Key = s3.key;
  const acceptedFiles = s3.content_type;
  const textArea = document.querySelector(el.dataset.textareaId);
  const { uploadId } = el.dataset;

  delete s3.key;
  delete s3.content_type;

  const dropzone = new Dropzone(elZone, {
    url,
    acceptedFiles,
    timeout: null,
    thumbnailWidth: 50,
    thumbnailHeight: 50,
  });

  dropzone.on('sending', (file, _, fd) => {
    Object.keys(s3).forEach((k) => {
      const v = s3[k];
      fd.append(k, v);
    });
    fd.append('key', s3Key + sanitize(file.name));
    fd.set('Content-Type', file.type);
  });

  const editorWrapper = el.closest('[data-behavior="markdown-editor-wrapper"]');
  if (editorWrapper) {
    dropzone.on('success', (file) => {
      const internalName = `upload://${uploadId}/${sanitize(file.name)}`;
      const editor = editorWrapper.querySelector(
        '[data-behavior="markdown-editor-widget"]',
      );
      // Dispatches event with the uploaded file data. The markdown editor
      // (markdown-editor/index.ts) listens to it and adds it to the textarea.
      const uploadedToDropzone = new CustomEvent('markdownEditor::addLink', {
        detail: { name: file.name, url: internalName },
      });
      editor.dispatchEvent(uploadedToDropzone);
    });
  } else {
    // For old markdown editors
    dropzone.on('addedfile', (file) => {
      const internalName = `upload://${uploadId}/${sanitize(file.name)}`;
      const externalName = `${url}/${s3Key}${sanitize(file.name)}`;
      textArea.xiUrlMapping[internalName] = externalName;
      textArea.xiUrlMappingInput.value = JSON.stringify(textArea.xiUrlMapping);
    });
  }
};

const scanMdUpload = (node) => {
  (node || document).querySelectorAll('[data-mdupload]').forEach((el) => {
    initMdUpload(el);
  });
};

ready(() => scanMdUpload());

export default {
  scan: scanMdUpload,
  init: initMdUpload,
};
