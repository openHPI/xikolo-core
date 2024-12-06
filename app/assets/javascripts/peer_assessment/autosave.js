$.fn.autosave = function () {
  var autoSave,
    autoSaveTime,
    autosave_button,
    changed,
    clearID,
    disable_buttons,
    enable_buttons,
    form,
    last_saved_container,
    submit_button,
    url;

  if ($(this).prop('tagName').toLowerCase() !== 'form') {
    console.error('Tried to initialize autosave on a non-form tag.');
    return;
  }

  // Autosave init stuff
  changed = false; // Flag indicating if the document has been changed
  clearID = -1; // Schedule identifier
  form = $(this); // The form to autosave
  url = $(form).data('autosave-url'); // Where to PATCH the request
  autoSaveTime = 10000; // Autosave interval
  autosave_button = $($(form).data('autosave-button')); // Which button should be the manual trigger
  submit_button = $($(form).data('submit-button')); // Which button submits the document
  last_saved_container = $($(form).data('last-saved-container')); // Where to show the last saved timestamp

  $(window).on('beforeunload', function (e) {
    // Synchronously save document state before unloading
    autoSave(false);
  });

  // On submit: clear the autosave to prevent double-saves, and disable the form buttons
  //$(form).on("submit", function() {
  //if (!$(form).hasClass('js-submit-confirm')) {
  //    console.error("Form to autosave does not have the class 'js-submit-confirm'.");
  //    return false;
  //}

  // If the user aborts the submit, don't do a thing.
  //if (!form.is("[data-confirmation-answer]") ) {
  //    return false;
  //}

  //if (!$(form).data('confirmation-answer')) {
  //    return false;
  //}

  //    clearTimeout(clearID);
  //
  //    $(submit_button).toggleClass('disabled').click(function(e) {
  //        e.preventDefault();
  //    });
  //
  //    $(autosave_button).toggleClass('disabled').click(function(e) {
  //        e.preventDefault();
  //    });
  //
  //    return true;
  //});

  // Works for most input types...
  $(form).change(function () {
    if (!changed) {
      changed = true;
    }
  });

  // ...but not text areas, so we have to catch changes to these separately.
  $(form)
    .find('textarea')
    .on('keydown change input', function () {
      if (!changed) {
        changed = true;
      }
    });

  // The manual trigger clears the scheduled autosave and reschedules (runs instantly) it with a guaranteed save (changed = true)
  $(autosave_button).click(function (e) {
    clearTimeout(clearID);
    changed = true;
    autoSave();
    e.preventDefault();
  });

  // Visually disables buttons and makes them unclickable (in most cases, at least), but does not set a preventDefault handler,
  // since these disables are only intended for shorter periods of time.
  disable_buttons = function () {
    $(autosave_button)
      .html($(autosave_button).data('save-text'))
      .attr('disabled', 'disabled')
      .addClass('disabled');
    $(submit_button).attr('disabled', 'disabled').addClass('disabled');
  };

  enable_buttons = function (label) {
    $(autosave_button)
      .html(label)
      .attr('disabled', false)
      .removeClass('disabled');
    $(submit_button).attr('disabled', false).removeClass('disabled');
  };

  // Main autosave functionality
  autoSave = function (async) {
    var label;
    if (async == null) {
      async = true;
    }

    // No changes? Let's check back again in a while...
    if (!changed) {
      clearID = setTimeout(autoSave, autoSaveTime);
      return;
    }

    label = $(autosave_button).html();
    disable_buttons();
    if (!async) {
      showLoading();
    }
    $.ajax({
      type: 'PATCH',
      url: url,
      data: $(form).serialize(),
      async: async,
      headers: {
        Accept: 'application/json; charset=utf-8',
      },
      dataType: 'json',
      error: function () {
        $(last_saved_container)
          .find('.last_saved')
          .html(
            '<span class="red">' +
              $(form).data('remote-error-message') +
              '</span>',
          );
      },
      success: function (data) {
        changed = false;
        if (data.success) {
          var relativeTime = getRelativeTime(new Date(data.timestamp));
          $(last_saved_container).find('.last_saved').text(relativeTime);

          clearID = setTimeout(autoSave, autoSaveTime);
        } else {
          if (data.hasOwnProperty('message')) {
            $(last_saved_container)
              .find('.last_saved')
              .html('<span class="red">' + data.message + '</span>');
          } else {
            $(last_saved_container)
              .find('.last_saved')
              .html(
                '<span class="red">' +
                  $(form).data('remote-error-message') +
                  '</span>',
              );
          }
        }
      },
      complete: function () {
        $(last_saved_container).removeClass('hidden');
        enable_buttons(label);
      },
    });
  };
  clearID = setTimeout(autoSave, autoSaveTime);
};
