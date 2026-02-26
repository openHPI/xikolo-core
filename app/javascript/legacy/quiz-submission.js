/**
 * Quiz Submission Handler
 * Handles quiz completion checking, auto-save functionality, and form submission
 */

import $ from 'jquery';
import { turboReady } from '../util/ready';
import { showLoading } from '../util/loading';

turboReady(function () {
  // Read configuration from meta tag
  const configMeta = document.querySelector(
    'meta[name="quiz-submission-config"]',
  );
  const config = configMeta ? JSON.parse(configMeta.content) : {};
  const graded = config.graded || false;

  // Listen for quiz completion check requests
  const submitButton = document.querySelector('#quiz_submit_button');

  if (submitButton) {
    submitButton.addEventListener('click', function (event) {
      event.preventDefault();
      if (graded) {
        const indicators = $('#quiz-state-indicators');
        if (
          indicators.find('.answer-state-indicator').size() !=
          indicators.find('.edited').size()
        ) {
          // not all questions answered
          $('.confirm-quiz-submission').modal('show');
          return false;
        }
      }
      $('#quiz_form').submit();
    });
  }

  var submitted = false;

  $('#quiz_form').on('submit', function () {
    if (graded) {
      $('.confirm-quiz-submission').modal('hide');
    }
    showLoading();

    // disable submit button after click
    $(this).find('input[type=submit]').prop('disabled', true);

    submitted = true;
    return true;
  });

  $.fn.changeTimestamp = function (isotime) {
    var relativeTime = window.getRelativeTime(new Date(isotime));
    return $(this)
      .attr('title', isotime)
      .data('timeago', null)
      .text(relativeTime);
  };

  var quizChanged = false;
  var autoSaveTime = 10000; // Auto-Save Quiz every 10 seconds

  $(window).on('beforeunload', function (event) {
    if (!submitted && graded) {
      event.preventDefault();
    }
  });

  // Quiz Auto-Save

  setTimeout(autoSaveQuiz, autoSaveTime);

  $('#quiz_form').change(function () {
    if (quizChanged == false) {
      quizChanged = true;
    }
  });

  function autoSaveQuiz() {
    if (quizChanged == true) {
      $.ajax({
        type: 'POST',
        url: config.autoSaveUrl,
        data: $('#quiz_form').serialize(),
        dataType: 'json',
        success: function (data) {
          if (data.success == true) {
            $('.warning-autosave').addClass('hide');
            try {
              $('abbr.last_saved').changeTimestamp(data.timestamp);
            } catch (err) {
              console.log(err);
            }
          } else {
            $('.warning-autosave').removeClass('hide');
          }
          quizChanged = false;
        },
        error: function () {
          $('.warning-autosave').removeClass('hide');
        },
      });
    }
    setTimeout(autoSaveQuiz, autoSaveTime);
  }
});
