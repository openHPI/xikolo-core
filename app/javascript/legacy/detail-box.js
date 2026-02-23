$(function () {
  $('#quiz_form input , #quiz_form select , #quiz_form textarea').change(
    function (evt) {
      var indicator_selector, quiz_question, target;
      target = window.event ? event.srcElement : evt.currentTarget;
      quiz_question = $(target).closest('.quiz-question');
      indicator_selector = '#' + quiz_question.attr('id') + '_indicator';
      if (quiz_question.find('input[type=text], textarea').size() > 0) {
        return;
      }
      if (quiz_question.find('input:checked').size() > 0) {
        return $(indicator_selector, '#quiz-state-indicators').addClass(
          'edited',
        );
      } else {
        return $(indicator_selector, '#quiz-state-indicators').removeClass(
          'edited',
        );
      }
    },
  );
  $('#quiz_form input , #quiz_form textarea').on('input', function (evt) {
    var indicator_selector, quiz_question, target;
    target = window.event ? event.srcElement : evt.currentTarget;
    quiz_question = $(target).closest('.quiz-question');
    indicator_selector = '#' + quiz_question.attr('id') + '_indicator';
    if (quiz_question.find('input, textarea').val().length > 0) {
      return $(indicator_selector, '#quiz-state-indicators').addClass('edited');
    } else {
      return $(indicator_selector, '#quiz-state-indicators').removeClass(
        'edited',
      );
    }
  });
  $('.quiz-sidebar').width($('.quiz-sidebar').parent().width());
  $(window).resize(function () {
    return $('.quiz-sidebar').width($('.quiz-sidebar').parent().width());
  });
  $('.quiz-sidebar').affix({
    offset: {
      top: function () {
        return $('#quiz-sidebar-wrapper').offset().top - 80;
      },
      bottom: function () {
        return $('.wrapper').offset().bottom;
      },
    },
  });
});
