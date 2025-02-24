import $ from 'jquery';
import ready from '../../util/ready';
import xuiSwal from '../../util/swal';
import fetch from '../../util/fetch';
import I18n from '../../i18n/i18n';
import handleError from '../../util/error';

const import_quizzes = new (function () {
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

  async function onOpenUpload() {
    const url = $('#import_quizzes_button').data('preview-url');
    const formData = new FormData();
    formData.append('xml', $('#preview_quizzes_xml_upload')[0].files[0]);

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (response.ok) {
        onUploadSuccess(data);
      } else {
        onUploadError(data);
      }
    } catch (error) {
      handleError('', error);
    }
  }

  function onUploadError(err) {
    const $errors = $('<ol class="error_list">');
    $.each(err.error, function (i, e) {
      $errors.append($('<li>' + e + '</li>'));
    });
    xuiSwal.fire({
      title: I18n.t('items.quiz.import.preview.errorTitle'),
      html: $errors[0].outerHTML,
      icon: 'error',
      showCancelButton: false,
      showCloseButton: true,
    });
  }

  function onUploadSuccess(data) {
    const $preview = generatePreview(data);

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
      preConfirm: async function () {
        delete data.params['preview'];
        const url = $('#import_quizzes_button').data('import-url');
        const formData = new FormData();
        formData.append('course_code', data.params.course_code);
        formData.append('course_id', data.params.course_id);
        formData.append('xml', data.params.xml);

        try {
          const response = await fetch(url, {
            method: 'POST',
            body: formData,
          });
          if (response.ok) {
            onImportSuccess(data);
          } else {
            onImportError(data);
          }
        } catch (error) {
          handleError('', error);
        }
      },
    });
  }

  function onImportError(err) {
    const $errors = $('<ol class="error_list">');
    $.each(err.error, function (i, e) {
      $errors.append($('<li>' + e + '</li>'));
    });
    xuiSwal.fire({
      title: I18n.t('items.quiz.import.errorTitle'),
      html: $errors[0].outerHTML,
      icon: 'error',
      showCancelButton: false,
      showCloseButton: true,
    });
  }

  function onImportSuccess() {
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
    const $preview = $('<div id="preview_container">');
    const $preview_table = $(
      '<table id="quizzes_preview_table" class="table table-striped table-bordered">',
    );
    $preview.append($preview_table);

    const $thead = $('<thead>');
    $preview_table.append($thead);

    const $trhead = $('<tr>');
    $thead.append($trhead);

    const $name = $('<th class="col-sm-5">');
    $name.text(I18n.t('items.quiz.import.preview.name'));
    $trhead.append($name);

    const $extref = $('<th class="col-sm-4">');
    $extref.text(I18n.t('items.quiz.import.preview.extrefid'));
    $trhead.append($extref);

    const $section = $('<th class="col-sm-1 fixed_width_100">');
    $section.text(I18n.t('items.quiz.import.preview.section'));
    $trhead.append($section);

    const $nquestions = $(
      '<th class="col-sm-1 fixed_width_100" title="' +
        'Number of Questions' +
        '">',
    );
    $nquestions.text(I18n.t('items.quiz.import.preview.questions'));
    $trhead.append($nquestions);

    const $nanswers = $(
      '<th class="col-sm-1 fixed_width_100" title="' +
        'Number of Answers' +
        '">',
    );
    $nanswers.text(I18n.t('items.quiz.import.preview.answers'));
    $trhead.append($nanswers);

    const $tbody = $('<tbody>');
    $preview_table.append($tbody);

    $.each(data.quizzes, function (index, value) {
      const $quiz = $('<tr>');
      $tbody.append($quiz);

      if (!value.new_record && value.external_ref) {
        $quiz.addClass('updated_record');
      }

      const $name = $(
        '<td title="Name: ' +
          value.name +
          '\ncourse code: ' +
          value.course_code +
          '">',
      );
      $name.text(value.name);
      $quiz.append($name);

      const $extref = $('<td title="' + value.external_ref + '">');
      $extref.text(value.external_ref ? value.external_ref : '');
      $quiz.append($extref);

      let section_value = value.section;
      if (value.subsection !== undefined) {
        section_value = section_value + '.' + value.subsection;
      }

      const $section = $('<td>');
      $section.text(section_value);
      $quiz.append($section);

      const $nquestions = $(
        '<td title="' + value.number_questions + ' Questions' + '">',
      );
      $nquestions.text(value.number_questions);
      $quiz.append($nquestions);

      const $nanswers = $(
        '<td title="' + value.number_answers + ' Answers' + '">',
      );
      $nanswers.text(value.number_answers);
      $quiz.append($nanswers);
    });

    const $legend = $('<div class="legend">');
    $legend.html(I18n.t('items.quiz.import.preview.legend'));
    $preview.append($legend);

    return $preview;
  }

  function anyNewRecords(quizzes) {
    return quizzes.some((quiz) => quiz.new_record === true);
  }
})();

await ready(function () {
  $('#import_quizzes_by_service_button').on('click', function () {
    import_quizzes.fromSpreadSheet();
  });

  $('#import_quizzes_button').on('click', function () {
    import_quizzes.fromXmlFile();
  });
});
