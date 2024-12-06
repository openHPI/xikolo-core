/**
 * This attaches JS behavior to the image upload input
 * See app/inputs/image_upload_input.rb
 */

import Dropzone from 'dropzone';
import ready from 'util/ready';
import sanitize from 'util/sanitize';

Dropzone.autoDiscover = false;

const showPreviousImage = (dropzone) => {
  // Show existing image in preview-zone
  const fileUrl = document.getElementsByName('file_url')[0];
  if (fileUrl && fileUrl.value !== '') {
    const mockFile = {
      name: fileUrl.value.split('/')[fileUrl.value.split('/').length - 1],
    };
    dropzone.emit('addedfile', mockFile);
    dropzone.files.push(mockFile);
    const currentImage = mockFile.previewElement.querySelector(
      '[data-dz-thumbnail]',
    );
    currentImage.alt = mockFile.name;
    currentImage.src = fileUrl.value;
    dropzone.emit('success', mockFile);
  }
};

const init = (el) => {
  const s3 = JSON.parse(el.dataset.s3);
  const url = new URL(el.dataset.imageupload);
  const { uploadId } = el.dataset;

  // (pre)process passed arguments:
  const s3Key = s3.key;
  const acceptedFiles = s3.content_type;
  delete s3.key;
  delete s3.content_type;

  const opts = {
    url,
    maxFiles: 1,
    acceptedFiles,
    thumbnailWidth: null,
    thumbnailHeight: null,
    previewsContainer: '.imageupload-current',
    previewTemplate:
      '<div class="dz-preview">' +
      '<img data-dz-thumbnail />' +
      '<div class="dz-actions">' +
      '<button class="dz-clear hidden" title="Reset file">' +
      '<i class="fas fa-times"></i>' +
      '</button>' +
      '</div>' +
      '</div>',
  };

  if (el.dataset.maxFilesize) {
    opts.maxFilesize = el.dataset.maxFilesize / 1024 / 1024;
  }
  let targetWidth = s3['x-amz-meta-image-target-width'];
  if (targetWidth) {
    targetWidth = parseInt(targetWidth, 10);
  }
  let targetHeight = s3['x-amz-meta-image-target-height'];
  if (targetHeight) {
    targetHeight = parseInt(targetHeight, 10);
  }

  if (targetWidth || targetHeight) {
    opts.resizeWidth = targetWidth;
    opts.resizeHeight = targetHeight;
    opts.thumbnailWidth = targetWidth;
    opts.thumbnailHeight = targetHeight;
    opts.thumbnailMethod = 'crop';
    opts.resizeMethod = 'crop';
  }

  if (el.dataset.errorSize) {
    opts.dictFileTooBig = el.dataset.errorSize;
  }

  if (el.dataset.errorType) {
    opts.dictInvalidFileType = el.dataset.errorType;
  }
  const elZone = el.querySelector('.xui-imageupload-zone');
  const elForm = document
    .querySelector(`[data-id=${el.dataset.id}]`)
    .closest(`.form-group.${el.dataset.id}`);

  if (elZone.dropzone) return;
  // Todo: How to get the dropzone imported?
  // Linter wants it, but it is also working without
  const dropzone = new Dropzone(elZone, opts);
  dropzone.hiddenFileInput.id = el.dataset.id;

  const uploadIdInput = document.getElementById('upload_id');
  const uriInput = document.getElementById('uri');
  const deletionInput = document.getElementById('deletion');

  dropzone.on('sending', (file, xhr, fd) => {
    fd.append('key', s3Key + sanitize(file.name));
    fd.set('Content-Type', file.type);
    Object.keys(s3).forEach((key) => fd.append(key, s3[key]));
    uriInput.value = `${uploadId}/${sanitize(file.name)}`;
    uriInput.disabled = false;
    uploadIdInput.disabled = false;
  });

  dropzone.on('thumbnail', (file) => {
    if (!(targetWidth || targetHeight)) return;
    // Do the dimension checks you want to do
    if (
      (targetWidth && file.width < targetWidth) ||
      (targetHeight && file.height < targetHeight)
    ) {
      file.done('Invalid dimensions');
    } else {
      file.done();
    }
  });

  dropzone.on('addedfile', (file) => {
    // Remove previously added file if there is any
    if (dropzone.files.length > 1) {
      dropzone.removeFile(dropzone.files[0]);
    }
    // If the previous file were to be deleted, take this instruction back
    deletionInput.disabled = true;

    // Hide deletion hint
    const hint = document.querySelector(
      "[data-behavior='remove-on-save-hint']",
    );
    if (hint) {
      hint.classList.add('hidden');
    }

    file.previewElement
      .querySelector('.dz-clear')
      .addEventListener('click', (e) => {
        // Do not delete the whole preview area
        e.preventDefault();

        // Remove previous error message if there is any
        if (elForm) {
          elForm.classList.remove('has-error');
          elForm
            .querySelectorAll('.has-error')
            .forEach((child) => child.remove());
        }

        file.previewElement
          .querySelector('[data-dz-thumbnail]')
          .classList.add('to-be-removed');
        deletionInput.disabled = false;
        uploadIdInput.disabled = true;
        uriInput.disabled = true;
        if (elForm) {
          elForm
            .querySelectorAll('.dz-actions')
            .forEach((child) => child.remove());
        }
        // Display hint
        if (hint) {
          hint.classList.remove('hidden');
        }
      });
  });

  dropzone.on('removedfile', (file) => {
    // Remove previous error message if there is any
    if (elForm) {
      elForm.classList.remove('has-error');
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }
    fetch(new URL(`${url}/${s3Key}${sanitize(file.name)}`), {
      method: 'DELETE',
    });
  });

  dropzone.on('error', (file, message, xhr) => {
    dropzone.removeFile(file);
    uploadIdInput.disabled = true;
    uriInput.disabled = true;
    // Show existing picture in preview-zone
    showPreviousImage(dropzone);

    let messageTemplate = message;
    if (elForm) {
      elForm.classList.add('has-error');
      // Remove previous error message if there is any
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }
    const replacements = {
      filetype: file.type,
      fileext: file.name.split('.').pop(),
    };

    if (xhr) {
      messageTemplate = dropzone.options.dictResponseError;
      replacements.statusCode = `${xhr.status} ${xhr.statusText}`;
    }
    const err = document.createElement('div');
    err.classList.add('help-block');
    err.classList.add('has-error');
    err.textContent = `${messageTemplate}`.replace(/\{\{(\w+)\}\}/g, (_, id) =>
      replacements[id] ? replacements[id] : `{{${id}}}`,
    );
    el.parentNode.appendChild(err);

    // If the previous file were to be deleted, take this instruction back
    deletionInput.disabled = true;
  });

  dropzone.on('success', () => {
    // Remove previous error message if there is any
    if (elForm) {
      elForm.classList.remove('has-error');
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }
    // Stop hiding the deletion button
    document.getElementsByClassName('dz-clear')[0].classList.remove('hidden');
  });

  // Show existing picture in preview-zone
  showPreviousImage(dropzone);
};

const scan = (node = document) =>
  Array.prototype.forEach.call(
    node.querySelectorAll('[data-imageupload]'),
    init,
  );

ready(() => scan());

window.xui = !window.xui ? {} : window.xui;
window.xui.imageupload = {
  scan,
  init,
  sanitize,
};
