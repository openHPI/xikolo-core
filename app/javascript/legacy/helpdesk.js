import $ from 'jquery';
import fetch from '../util/fetch';
import { turboReady } from '../util/ready';
import handleError from '../util/error';

// Module-level state so turbo:before-cache can reset all session vars
let newSession = true;
let helpdeskStatus = 'default';
let helpDeskTabOpen = false;

// Register the cache-clearing listener at module scope (runs once on first
// import). A turbo:before-cache handler lets us clean the helpdesk DOM and
// reset session state before Turbo caches the page, so no stale reCAPTCHA
// widget or half-finished form is ever reused after navigation.
document.addEventListener('turbo:before-cache', () => {
  $('#helpdesk-panel').hide();
  $('#helpdesk-ajax-container').empty();
  $('.grecaptcha-badge').remove();
  newSession = true;
  helpdeskStatus = 'default';
  helpDeskTabOpen = false;
});

turboReady(() => {
  const load = function (helpdeskType = '') {
    $('#helpdesk-panel__loading').show();

    try {
      window.grecaptcha?.reset();
    } catch (error) {
      // grecaptcha may not be loaded yet — will be created on next render
      handleError('grecaptcha not loaded yet', error);
    }
    $('#helpdesk-ajax-container').load(helpdeskURL(helpdeskType), function () {
      if ($('#course_id_container').text()) {
        $('select#category').val($('#course_id_container').text()).change();
      }

      $('#helpdesk-panel__loading').hide();

      document
        .querySelector('.helpdesk-closing-button')
        .addEventListener('click', closeHelpdeskLayer);

      window.initTabNavigation();

      const helpdeskForm = document.querySelector(
        `#helpdesk-form${helpdeskType}`,
      );
      helpdeskForm.addEventListener('submit', async function (event) {
        event.preventDefault();

        const { report, title, category, topic, mail } = getFormParams();
        const url = document.URL,
          userAgent = navigator.userAgent,
          language = navigator.language,
          cookieEnabled = navigator.cookieEnabled,
          recaptcha_token_v2 = checkboxRecaptcha(helpdeskType)
            ? window.grecaptcha.getResponse()
            : null,
          recaptcha_token_v3 = $(
            'input#g-recaptcha-response-data-helpdesk',
          ).val();

        const formData = new FormData();
        formData.append('report', report);
        formData.append('url', url);
        formData.append('topic', topic);
        formData.append('userAgent', userAgent);
        formData.append('language', language);
        formData.append('category', category);
        formData.append('cookie', cookieEnabled);
        formData.append('title', title);
        formData.append('mail', mail);
        if (recaptcha_token_v2) {
          formData.append('recaptcha_token_v2', recaptcha_token_v2);
        }
        if (recaptcha_token_v3) {
          formData.append('recaptcha_token_v3', recaptcha_token_v3);
        }

        try {
          const response = await fetch('/helpdesk/', {
            method: 'POST',
            body: formData,
          });

          if (!response.ok) {
            handleError('', response.statusText, false);
          }

          const responseText = await response.text();
          $('#helpdesk-panel .helpdesk-result-box').html(responseText);

          if (responseText.includes('checkbox_recaptcha')) {
            helpdeskStatus = 'with-checkbox-recaptcha';
            $('#helpdesk-panel .helpdesk-default-box').fadeOut(
              'slow',
              function () {
                $('#helpdesk-ajax-container').fadeIn('slow');
                load('-with-checkbox-recaptcha');
              },
            );
          } else {
            fadeInResult();
            helpdeskStatus = `success-${helpdeskStatus}`;

            helpdeskForm.reset();
          }
        } catch (error) {
          fadeInResult();
          $('#helpdesk-panel .helpdesk-result-box').html(error.message);
          helpdeskStatus = 'error';
        }
      });
    });
  };

  const helpdeskURL = function (helpdeskType) {
    let url = '/helpdesk';
    const params = getFormParams();
    // Filter out falsy values from params (undefined, null, '', 0, NaN)
    const filteredParams = Object.fromEntries(
      Object.entries(params).filter(([, value]) => value),
    );
    // Add the show_checkbox_recaptcha parameter if needed
    if (checkboxRecaptcha(helpdeskType)) {
      filteredParams.show_checkbox_recaptcha = true;
    }
    const queryString = new URLSearchParams(filteredParams).toString();
    return queryString ? `${url}?${queryString}` : url;
  };

  const checkboxRecaptcha = function (helpdeskType) {
    return helpdeskType == '-with-checkbox-recaptcha';
  };

  const getFormParams = function () {
    return {
      report: $('#issuereport').val(),
      title: $('#issuetitle').val(),
      category: $('#category').val(),
      topic: $("input[name='question_topic']:checked").val(),
      mail: $('#issueemail').val(),
    };
  };

  const fadeInResult = function () {
    $('#helpdesk-panel .helpdesk-default-box').fadeOut('slow', function () {
      $('#helpdesk-panel .helpdesk-result-box').fadeIn('slow');
    });
  };

  // Global method to allow opening the helpdesk from static links, e.g. in the footer
  window.openHelpdeskLayer = function () {
    // load helpdesk initially
    if (newSession) {
      load();
      newSession = false;
    }
    helpDeskTabOpen = true;

    $('#helpdesk-panel').show();
    $('#helpdesk-panel .helpdesk-default-box').show();
    $('#helpdesk-panel .helpdesk-result-box').hide();
  };

  function closeHelpdeskLayer() {
    $('#helpdesk-panel').hide();

    if (helpdeskStatus === 'default') {
      // helpdesk was closed without submitting a ticket
      $('#helpdesk-panel .helpdesk-default-box').fadeOut('fast');
      $('#helpdesk-panel .helpdesk-result-box').hide();
    } else if (helpdeskStatus === 'success-with-checkbox-recaptcha') {
      // We need to reset the form to remove the V2 recaptcha
      load();
      helpdeskStatus = 'default';
    } else {
      // helpdesk was closed after a ticket was submitted
      $('#helpdesk-panel .helpdesk-result-box').fadeOut('fast', function () {
        $('#helpdesk-panel .helpdesk-default-box').hide();
        helpdeskStatus = 'default';
      });
    }

    helpDeskTabOpen = false;
  }

  $('#helpdesk-button').show();

  $('#helpdesk-button').on('click', function () {
    if (helpDeskTabOpen == false) {
      window.openHelpdeskLayer();
    } else {
      closeHelpdeskLayer();
    }
  });

  $('.helpdesk-container').on(
    'click',
    '[data-behavior=close-helpdesk]',
    function () {
      closeHelpdeskLayer();
      document.querySelector('[id^="helpdesk-form"]');
    },
  );

  $('.helpdesk-container').on(
    'click',
    '[data-behavior=back-to-form]',
    function (event) {
      event.preventDefault();
      $('#helpdesk-panel .helpdesk-result-box').hide();
      $('#helpdesk-panel .helpdesk-default-box').fadeIn('medium');
    },
  );
});
