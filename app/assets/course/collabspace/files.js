import ready from 'util/ready';
import sanitize from '../../util/sanitize';
import './files.scss';

ready(() => {
  const dzElem = document.querySelector(
    '#new_collabspace_file .xui-upload-zone',
  );
  if (!dzElem) return;

  dzElem.dropzone.on('success', (file) => {
    const form = document.querySelector('#new_collabspace_file');
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'collabspace_file[file_upload_name]';
    input.value = sanitize(file.name);
    form.appendChild(input);
    form.submit();
  });
});