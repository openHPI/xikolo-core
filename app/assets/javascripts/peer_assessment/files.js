// Converts a byte count into a human-readable representation (base 1000 or 1024)
function humanFileSize(bytes, si) {
  var thresh = si ? 1000 : 1024;
  if (bytes < thresh) return bytes + ' B';
  var units = si
    ? ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    : ['KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
  var u = -1;
  do {
    bytes /= thresh;
    ++u;
  } while (bytes >= thresh);
  return bytes.toFixed(1) + ' ' + units[u];
}

// Registers a deletion handler linked to a dropzone (i.e. to remove a file preview)
function register_deletion_handler(element, dropzone, file) {
  $(element).submit(function (e) {
    e.preventDefault();

    xuiSwal
      .fire({
        title: $(this).data('confirm-title'),
        text: $(this).data('confirm-text'),
        icon: 'warning',
        confirmButtonText: I18n.t('peer_assessment.files.confirm_button'),
        cancelButtonText: I18n.t('global.cancel'),
      })
      .then(function (result) {
        if (result.value) {
          $('#submission_form_submit_button')
            .prop('disabled', true)
            .addClass('disabled');
          $(element).find('button').prop('disabled', true);

          $.post(
            $(element).attr('action'),
            $(element).serialize(),
            function (data, status) {
              if (data.success) {
                $($(element).parents()[1]).remove();
              }

              $(element).find('button').prop('disabled', false);
              $('#submission_form_submit_button')
                .prop('disabled', false)
                .removeClass('disabled');

              if (file) {
                dropzone.removeFile(file);
              }
            },
            'json',
          );
        }
      });

    return false;
  });
}
