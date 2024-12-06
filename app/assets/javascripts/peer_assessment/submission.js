// Disabling autoDiscover, otherwise Dropzone will try to attach twice and throw an error
Dropzone.autoDiscover = false;

ready(function () {
  var time;
  var clearID;
  var timer_seen = false;

  // This check should be sufficient to check if we are on the submisison page
  if ($('#submission_form_submit_button').length == 1) {
    var form = $('#submission_form');

    // The submission is done in two steps and thus slightly more complex than "normal", hence no .js-submit-confirm is used!
    form.submit(function () {
      window.clearTimeout(clearID);
      time = 4;

      //If the user uploaded files, show the first window, which reminds the user to check files.
      if (
        $('#user_files').length == 1 &&
        $('#user_files').find('tbody').children().length > 0
      ) {
        // Show popup
        xuiSwal
          .fire({
            title: I18n.t(
              'peer_assessment.submission.confirmation_window.title',
            ),
            text: I18n.t('peer_assessment.submission.confirmation_window.text'),
            icon: 'info',
            confirmButtonText: I18n.t(
              'peer_assessment.submission.confirmation_window.confirm_button',
            ),
            cancelButtonText: I18n.t('global.cancel'),
          })
          .then(function (result) {
            if (result.value) {
              // Show the final form submission confirmation
              xuiSwal
                .fire({
                  title: I18n.t('peer_assessment.submission.submit_title'),
                  text: I18n.t('peer_assessment.submission.submit'),
                  icon: 'warning',
                  confirmButtonText: I18n.t('global.confirm'),
                  cancelButtonText: I18n.t('global.cancel'),
                })
                .then(function (submit_form) {
                  if (submit_form.value) {
                    showLoading();
                    form.off('submit');
                    form.submit();
                  }
                });
            }
          });

        // Count down the button, so that users do not simply click instantly...
        if (!timer_seen) {
          // Count down only once
          var confirm_button = $('.sweet-alert').find('button.confirm');
          confirm_button.prop('disabled', true);
          confirm_button.addClass('disabled');
          count_down();
          timer_seen = true;
        }

        // Copy file table to the popup for sake of convenience
        var copy = $('#user_files').find('table').clone();
        copy.addClass('mt10');
        copy.find('.js-delete-file').remove(); // No deletion button here, which would make things too difficult
        copy.find('thead').children().remove(); // no header
        $(copy.find('tr')).each(function (index, element) {
          $($(element).children()[1]).remove(); // There are three children - remove the size col, which is second
        });

        $('.sweet-alert').find('p').first().append(copy);
      } else {
        // Show the final form submission confirmation without the file window
        xuiSwal
          .fire({
            title: I18n.t('peer_assessment.submission.submit_title'),
            text: I18n.t('peer_assessment.submission.submit'),
            icon: 'warning',
            confirmButtonText: I18n.t('global.confirm'),
            cancelButtonText: I18n.t('global.cancel'),
          })
          .then(function (result) {
            if (result.value) {
              showLoading();
              form.off('submit');
              form.submit();
            }
          });
      }

      return false;
    });

    if (form.data().hasOwnProperty('autosaveUrl')) {
      form.autosave();
    }

    // Fallback for old browsers, which do not have HTML5 input elements outside of forms
    $('#submission_form_submit_button').click(function () {
      submit_form_force_events(document.getElementById('submission_form'));
    });

    // Data passed through the submission form to configure dropzone js and the ajax callback
    var allowed_file_types = form.data('allowed-file-types');
    var max_file_size = form.data('max-file-size');
    var assessment_id = form.data('assessment-id');
    var current_step_id = form.data('current-step-id');
    var authenticity_token = form.data('authenticity-token');

    // Internationalizations for the file table
    var download_text = I18n.t('peer_assessment.files.download_button');
    var delete_message = I18n.t(
      'peer_assessment.submission.delete_file_message',
    );
    var delete_button_text = I18n.t('peer_assessment.submission.delete_file');

    if ($('#submission_upload')) {
      var submission_upload_dropzone = new Dropzone('#submission_upload', {
        maxFilesize: max_file_size,
        uploadMultiple: false,
        parallelUploads: 1,
        acceptedFiles: allowed_file_types,
        dictDefaultMessage: I18n.t(
          'peer_assessment.files.upload_default_message',
        ),
        timeout: 0,
      });

      $('.js-delete-file').each(function (index, element) {
        register_deletion_handler(element, submission_upload_dropzone);
      });

      // Check if the dropzone creation succeeded
      if ('on' in submission_upload_dropzone) {
        submission_upload_dropzone.on('addedfile', function (file) {
          $('#submission_form_submit_button')
            .prop('disabled', true)
            .addClass('disabled');
        });

        submission_upload_dropzone.on('sending', function (file, xhr, fd) {
          fd.append(
            'key',
            $('#submission_upload').data('key') + sanitize(file.name),
          );
          fd.set('Content-Type', file.type);
        });

        submission_upload_dropzone.on('success', function (file, responseText) {
          file.previewElement.className =
            'dz-preview dz-processing dz-image-preview';
          $.ajax({
            url: $('#submission_upload').data('url'),
            method: 'POST',
            data: {
              upload_uri:
                $('#submission_upload').data('prefix') + sanitize(file.name),
            },
            success: function (data, status, xhr) {
              file.previewElement.className =
                'dz-preview dz-processing dz-success dz-image-preview';
              $('#user_files table').removeClass('hidden');
              $('#user_files tbody').append(
                '<tr>' +
                  '<td>' +
                  sanitize(file.name) +
                  '</td>' +
                  '<td>' +
                  humanFileSize(file.size, true) +
                  '</td>' +
                  '<td>' +
                  '<a class="btn btn-primary btn-xs" href="' +
                  data.upload.download_url +
                  '" target="blank">' +
                  download_text +
                  '</a>' +
                  '<form accept-charset="UTF-8" action="/peer_assessments/' +
                  assessment_id +
                  '/steps/' +
                  current_step_id +
                  '/submission/remove_file" class="inline-block js-delete-file" data-confirm-text="' +
                  delete_message +
                  '" data-confirm-title="' +
                  delete_message +
                  '" enctype="multipart/form-data" method="post">' +
                  '<div style="margin:0; padding:0; display:inline">' +
                  '<input name="utf8" type="hidden" value="✓">' +
                  '<input name="_method" type="hidden" value="delete">' +
                  '<input name="authenticity_token" type="hidden" value="' +
                  authenticity_token +
                  '">' +
                  '</div>' +
                  '<input id="file_id" name="file_id" type="hidden" value="' +
                  data.upload.id +
                  '">' +
                  '<input id="peer_assessment_id" name="peer_assessment_id" type="hidden" value="' +
                  assessment_id +
                  '">' +
                  '<button class="btn btn-xs btn-danger ml5" type="submit">' +
                  delete_button_text +
                  '</button>' +
                  '</form>' +
                  '</td>' +
                  '</tr>',
              );

              register_deletion_handler(
                $('#user_files form').last(),
                submission_upload_dropzone,
                file,
              );
            },
            error: function (xhr, textStatus, error) {
              file.previewElement.className =
                'dz-preview dz-processing dz-image-preview dz-error';
            },
          });

          $('#submission_form_submit_button')
            .prop('disabled', false)
            .removeClass('disabled');
        });

        submission_upload_dropzone.on('error', function (file) {
          window.setTimeout(function () {
            submission_upload_dropzone.removeFile(file);
          }, 5000);

          $('#submission_form_submit_button')
            .prop('disabled', false)
            .removeClass('disabled');
        });
      }
    }
  }

  function count_down() {
    var button = $('.sweet-alert').find('button.confirm');

    if (time == 0) {
      button.prop('disabled', false);
      button.removeClass('disabled');
      button.html(
        I18n.t('peer_assessment.submission.confirmation_window.confirm_button'),
      );
      return;
    } else {
      button.html(time);
    }

    time -= 1;
    clearID = window.setTimeout(count_down, 1000);
  }
});
