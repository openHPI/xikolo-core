/**
 * This attaches JS behavior to the upload input
 * See app/inputs/upload_input.rb
 */

import Dropzone from '../../../../vendor/assets/javascripts/dropzone';
import ready from '../ready';
import sanitize from '../sanitize';

Dropzone.autoDiscover = false;

const previewTemplate = `\
<div class="dz-preview">
  <img class="dz-thumb"  data-dz-thumbnail />
  <div class="dz-details">
    <div class="dz-info">
      <span class="dz-filename" data-dz-name></span>
      <span class="dz-size" data-dz-size></span>
    </div>
    <div class="dz-progress">
      <div data-dz-uploadprogress></div>
    </div>
  </div>
  <div class="dz-actions">
    <button class="dz-clear" title="Reset file"><i class="fas fa-times"></i></button>
  </div>
</div>\
`;

// Preprocess passed arguments
const getDropzoneOpts = (dataset, s3) => {
  const acceptedFiles = s3.content_type;
  const url = dataset.upload;

  const opts = {
    url,
    maxFiles: 1,
    acceptedFiles,
    timeout: null,
    previewTemplate,
  };

  if (dataset.maxFilesize) {
    opts.maxFilesize = dataset.maxFilesize / 1024 / 1024;
  }

  let targetWidth = s3['x-amz-meta-image-target-width'];
  if (targetWidth) {
    targetWidth = parseInt(targetWidth, 10);
  }

  let targetHeight = s3['x-amz-meta-image-target-height'];
  if (targetHeight) {
    targetHeight = parseInt(targetHeight, 10);
  }

  const resizingImage = targetWidth || targetHeight;

  if (resizingImage) {
    opts.resizeWidth = targetWidth;
    opts.resizeHeight = targetHeight;
    opts.resizeMethod = 'crop';
  }

  if (dataset.errorSize) {
    opts.dictFileTooBig = dataset.errorSize;
  }

  if (dataset.errorType) {
    opts.dictInvalidFileType = dataset.errorType;
  }

  return opts;
};

const init = (el) => {
  const elZone = el.querySelector('.xui-upload-zone');

  if (!elZone || elZone.dropzone != null) {
    return;
  }

  const s3 = JSON.parse(el.dataset.s3);
  const s3Key = s3.key;
  const opts = getDropzoneOpts(el.dataset, s3);

  delete s3.key;
  delete s3.content_type;

  const dropzone = new Dropzone(elZone, opts);
  dropzone.hiddenFileInput.id = el.dataset.id;

  elZone.addEventListener('keydown', (e) => {
    if (e.target !== elZone) {
      return;
    }
    if (e.keyCode !== 13 && e.keyCode !== 32) {
      return;
    }
    e.preventDefault();
    dropzone.hiddenFileInput.click();
  });

  dropzone.on('sending', (file, _, fd) => {
    Object.entries(s3).forEach(([key, value]) => {
      fd.append(key, value);
    });

    fd.append('key', s3Key + sanitize(file.name));
    fd.set('Content-Type', file.type);
  });

  dropzone.on('thumbnail', (file) => {
    if (!opts.resizingImage) {
      return;
    }

    // Do the dimension checks you want to do
    if (
      (opts.targetWidth && file.width < opts.targetWidth) ||
      (opts.targetHeight && file.height < opts.targetHeight)
    ) {
      file.done('Invalid dimensions');
    }
    file.done();
  });

  dropzone.on('addedfile', (file) => {
    // Remove previously added file if there is any
    if (dropzone.files.length > 1) {
      dropzone.removeFile(dropzone.files[0]);
    }

    file.previewElement.addEventListener('click', (e) => {
      if (!e.defaultPrevented) {
        e.preventDefault();
        dropzone.hiddenFileInput.click();
      }
    });

    const clearElement = file.previewElement.querySelector('.dz-clear');
    if (clearElement) {
      clearElement.addEventListener('click', (e) => {
        e.preventDefault();
        dropzone.removeFile(file);
      });
    }
  });

  const elForm = el.closest('.form-group');

  dropzone.on('removedfile', (file) => {
    if (elForm) {
      elForm.classList.remove('has-error');
      elForm.classList.remove('has-success');
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }
    fetch(new URL(`${opts.url}/${s3Key}${sanitize(file.name)}`), {
      method: 'DELETE',
    });
  });

  dropzone.on('error', (file, msg, xhr) => {
    let message = msg;
    if (elForm) {
      elForm.classList.add('has-error');
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }

    const replacements = {
      filetype: file.type,
      fileext: file.name.split('.').pop(),
    };

    if (xhr) {
      message = dropzone.options.dictResponseError;
      replacements.statusCode = `${xhr.status} ${xhr.statusText}`;
    }

    const err = document.createElement('div');
    err.classList.add('help-block');
    err.classList.add('has-error');

    err.textContent = `${message}`.replace(/\{\{(\w+)\}\}/g, (_, id) => {
      if (replacements[id]) {
        return replacements[id];
      }
      return `{{${id}}}`;
    });

    el.parentNode.appendChild(err);
  });

  dropzone.on('success', () => {
    if (elForm) {
      elForm.classList.remove('has-error');
      elForm.classList.add('has-success');
      elForm.querySelectorAll('.has-error').forEach((e) => e.remove());
    }
  });

  dropzone.on('uploadprogress', (file, progress) => {
    const previewElement = file.previewElement.querySelector('progress');
    if (previewElement) {
      previewElement.value = progress;
    }
  });
};

const scan = (node) => {
  (node || document).querySelectorAll('[data-upload]').forEach((el) => {
    init(el);
  });
};

ready(() => scan());

export default {
  scan,
  init,
};
