// this should go to course admin JS bundle

ready(function () {
  $('#import_quizzes_by_service_button').on('click', function (e) {
    import_quizzes.fromSpreadSheet();
  });

  $('#import_quizzes_button').on('click', function (e) {
    import_quizzes.fromXmlFile();
  });
});

var import_quizzes = new (function () {
  // public accessible start methods

  this.fromXmlFile = function () {
    xuiSwal
      .fire({
        title: I18n.t('items.quiz.import.download'),
        html:
          '<div class="fileinput fileinput-new" data-provides="fileinput">' +
          '  <input type="file" id="preview_quizzes_xml_upload" name="xml" accept="text/xml">' +
          '  <span class="fileinput-filename"></span>' +
          '</div>',
        confirmButtonText: I18n.t('items.quiz.import.confirmButtonText'),
        cancelButtonText: I18n.t('global.cancel'),
      })
      .then(function (result) {
        if (result.value) {
          onOpenUpload();
        }
      });
  };

  this.fromSpreadSheet = function () {
    xuiSwal
      .fire({
        title: I18n.t('items.quiz.import_quizzes_by_service'),
        html:
          '<form>' +
          '  <div class="form-group">' +
          '    <label for="spreadsheet">Spreadsheet</label>' +
          '    <input class="form-control" id="spreadsheet" type="text">' +
          '  </div>' +
          '  <div class="form-group">' +
          '    <label for="worksheet">Worksheet</label>' +
          '    <input class="form-control" id="worksheet" type="text">' +
          '  </div>' +
          '</form>',
        confirmButtonText: I18n.t('global.submit'),
        cancelButtonText: I18n.t('global.cancel'),
      })
      .then(function (result) {
        if (result.value) {
          $('#import_quizzes_by_service_spreadsheet').val(
            $('#spreadsheet').val(),
          );
          $('#import_quizzes_by_service_worksheet').val($('#worksheet').val());
          $('#import_quizzes_by_service_form').submit();
        }
      });

    return false;
  };

  // import steps

  function onOpenUpload() {
    var fd = new FormData();
    fd.append('xml', $('#preview_quizzes_xml_upload')[0].files[0]);

    $.ajax({
      url: $('#import_quizzes_button').data('preview-url'),
      data: fd,
      processData: false,
      contentType: false,
      type: 'POST',
      error: function (err) {
        onUploadError(err);
      },
      success: function (data) {
        onUploadSuccess(data);
      },
    });
  }

  function onUploadError(err) {
    $errors = $('<ol class="error_list">');
    $.each(err.responseJSON.error, function (i, e) {
      $errors.append($('<li>' + e + '</li>'));
    });
    xuiSwal.fire({
      title: I18n.t('items.quiz.import.preview.errorTitle'),
      html: $errors[0].outerHTML,
      icon: 'error',
    });
  }

  function onUploadSuccess(data) {
    $preview = generatePreview(data);

    xuiSwal.fire({
      title: I18n.t('items.quiz.import.preview.title'),
      html: $preview[0].outerHTML,
      didOpen: function () {
        const button = xuiSwal.getConfirmButton();
        if (!anyNewRecords(data.quizzes)) {
          button.disabled = true;
        }
      },
      confirmButtonText: I18n.t('items.quiz.import.preview.confirmButtonText'),
      cancelButtonText: I18n.t('global.cancel'),
      showLoaderOnConfirm: true,
      allowOutsideClick: false,
      width: '1020px',
      preConfirm: function () {
        return new Promise(function (resolve) {
          delete data.params['preview'];
          $.ajax({
            type: 'POST',
            url: $('#import_quizzes_button').data('import-url'),
            data: data.params,
            error: function (err) {
              onImportError(err);
            },
            success: function (data) {
              onImportSuccess(data);
            },
          });
        });
      },
    });
  }

  function onImportError(err) {
    $errors = $('<ol class="error_list">');
    $.each(err.responseJSON.error, function (i, e) {
      $errors.append($('<li>' + e + '</li>'));
    });
    xuiSwal.fire({
      title: I18n.t('items.quiz.import.errorTitle'),
      html: $errors[0].outerHTML,
      icon: 'error',
    });
  }

  function onImportSuccess(data) {
    xuiSwal
      .fire({
        title: I18n.t('items.quiz.import_quizzes_success'),
        icon: 'success',
        showCancelButton: false,
      })
      .then(function () {
        window.location.reload();
      });
  }

  // helper

  function generatePreview(data) {
    $preview = $('<div id="preview_container">');
    $preview_table = $(
      '<table id="quizzes_preview_table" class="table table-striped table-bordered">',
    );
    $preview.append($preview_table);
    $thead = $('<thead>');
    $preview_table.append($thead);
    $trhead = $('<tr>');
    $thead.append($trhead);
    $name = $('<th class="col-sm-5">');
    $name.text(I18n.t('items.quiz.import.preview.name'));
    $trhead.append($name);
    $extref = $('<th class="col-sm-4">');
    $extref.text(I18n.t('items.quiz.import.preview.extrefid'));
    $trhead.append($extref);
    $section = $('<th class="col-sm-1 fixed_width_100">');
    $section.text(I18n.t('items.quiz.import.preview.section'));
    $trhead.append($section);
    $nquestions = $(
      '<th class="col-sm-1 fixed_width_100" title="' +
        'Number of Questions' +
        '">',
    );
    $nquestions.text(I18n.t('items.quiz.import.preview.questions'));
    $trhead.append($nquestions);
    $nanswers = $(
      '<th class="col-sm-1 fixed_width_100" title="' +
        'Number of Answers' +
        '">',
    );
    $nanswers.text(I18n.t('items.quiz.import.preview.answers'));
    $trhead.append($nanswers);

    $tbody = $('<tbody>');
    $preview_table.append($tbody);

    $.each(data.quizzes, function (index, value) {
      $quiz = $('<tr>');
      $tbody.append($quiz);

      if (!value.new_record && value.external_ref) {
        $quiz.addClass('updated_record');
      }

      $name = $(
        '<td title="Name: ' +
          value.name +
          '\ncourse code: ' +
          value.course_code +
          '">',
      );
      $name.text(value.name);
      $quiz.append($name);
      $extref = $('<td title="' + value.external_ref + '">');
      $extref.text(value.external_ref ? value.external_ref : '');
      $quiz.append($extref);

      var section_value = value.section;
      if (value.subsection !== undefined) {
        section_value = section_value + '.' + value.subsection;
      }
      $section = $('<td>');
      $section.text(section_value);
      $quiz.append($section);
      $nquestions = $(
        '<td title="' + value.number_questions + ' Questions' + '">',
      );
      $nquestions.text(value.number_questions);
      $quiz.append($nquestions);
      $nanswers = $('<td title="' + value.number_answers + ' Answers' + '">');
      $nanswers.text(value.number_answers);
      $quiz.append($nanswers);
    });

    $legend = $('<div class="legend">');
    $legend.html(I18n.t('items.quiz.import.preview.legend'));
    $preview.append($legend);

    return $preview;
  }

  function anyNewRecords(quizzes) {
    return quizzes.some((quiz) => quiz.new_record === true);
  }
})();
