/**
 * Quiz Submission Handler
 * Handles quiz completion checking, auto-save functionality, and form submission
 */

import $ from 'jquery';
import { turboReady } from '../util/ready';
import { showLoading } from '../util/loading';
import getRelativeTime from '../util/get-relative-time';

turboReady(function () {
  // Read configuration from meta tag
  const configMeta = document.querySelector(
    'meta[name="quiz-submission-config"]',
  );
  if (!configMeta) return;

  const config = JSON.parse(configMeta.content);
  const graded = config.graded || false;

  // Listen for quiz completion check requests. Both the submit button in the
  // top card and the one at the bottom of the questions share this behavior.
  const submitButtons = document.querySelectorAll(
    'button[type="submit"][form="quiz_form"]',
  );

  submitButtons.forEach(function (submitButton) {
    submitButton.addEventListener('click', function (event) {
      event.preventDefault();
      if (graded) {
        const indicators = document.querySelector('#quiz-state-indicators');
        if (
          indicators &&
          indicators.querySelectorAll('.x-step').length !==
            indicators.querySelectorAll('.x-step[data-answered]').length
        ) {
          // not all questions answered
          $('.confirm-quiz-submission').modal('show');
          return false;
        }
      }
      $('#quiz_form').submit();
    });
  });

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
    var relativeTime = getRelativeTime(new Date(isotime));
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
            $('.warning-autosave').prop('hidden', true);
            try {
              $('abbr.last_saved').changeTimestamp(data.timestamp);
            } catch (err) {
              console.log(err);
            }
          } else {
            $('.warning-autosave').prop('hidden', false);
          }
          quizChanged = false;
        },
        error: function () {
          $('.warning-autosave').prop('hidden', false);
        },
      });
    }
    setTimeout(autoSaveQuiz, autoSaveTime);
  }
});
