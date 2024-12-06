(function () {
  var template;
  var edit_template;
  var form;

  ready(function () {
    form = $('#new_note_form');

    if (form.length) {
      template = $('#note_template').remove().removeAttr('id');
      edit_template = $('#edit_template').remove().removeAttr('id');

      form.submit(function () {
        disable_button(form.find('button[type="submit"]'));

        $.post('/notes', form.serialize())
          .done(function (data) {
            add_note(data);
            form.find('textarea').val('');
          })
          .fail(function (data) {
            display_error(data);
          })
          .always(function () {
            enable_button(form.find('button[type="submit"]'));
          });

        return false;
      });

      $('.js-note-delete').each(function (index, element) {
        add_action_handlers(element);
      });
    }
  });

  function add_action_handlers(element) {
    var delete_form = $(element);
    delete_form.submit(function (e) {
      e.preventDefault();
      disable_button(delete_form.find('button[type="submit"]'));

      xuiSwal
        .fire({
          title: I18n.t('peer_assessment.notes.delete_confirm_title'),
          text: I18n.t('peer_assessment.notes.delete_confirm_text'),
          icon: 'warning',
          confirmButtonText: I18n.t('global.delete'),
          cancelButtonText: I18n.t('global.cancel'),
        })
        .then(function (result) {
          if (result.value) {
            $.post(delete_form.attr('action'), delete_form.serialize())
              .done(function (data) {
                $('#' + data['id']).remove();
              })
              .fail(function (data) {
                $('#' + data['id']).remove();
                display_error(data);
                enable_button(delete_form.find('button[type="submit"]'));
              });
          }
        });

      return false;
    });
  }

  function enable_button(button) {
    button.prop('disabled', false).removeClass('disabled');
  }

  function disable_button(button) {
    button.prop('disabled', true).addClass('disabled');
  }

  function add_note(note) {
    new_note = template.clone();
    new_note.attr('id', note['id']);
    $(new_note.find('td')[0]).html(note['author']);
    $(new_note.find('td')[1]).html(note['created_at']);
    $(new_note.find('td')[2]).html(note['text']);

    var delete_form = new_note.find('.js-note-delete');
    delete_form.attr('action', delete_form.attr('action') + note['id']);
    add_action_handlers(delete_form);

    $('#notes').find('tbody').append(new_note);
  }

  function display_error(data) {
    xuiSwal.fire(
      I18n.t('peer_assessment.notes.error_header'),
      data.responseJSON['message'],
      'error',
    );
  }
})();
