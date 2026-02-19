import $ from 'jquery';
import fetch from '../util/fetch';
import ready from '../util/ready';
import handleError from '../util/error';

await ready(() => {
  let newSession = true;
  // Generate a new "session" identifier so that we can relate tracking events to each other
  const helpdeskSession = Math.random().toString(36).substr(2, 12);

  const load = function (helpdeskType = '') {
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

            track('helpdesk_ticket_created', {
              report: report,
              topic: category,
              question: title,
            });
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

  const track = function (verb, context) {
    // We currently cannot track events for guest users
    if (!window.gon.user_id) return;

    context['helpdesk_session_id'] = helpdeskSession;
    context['language'] = I18n.locale;

    $(document).trigger('track-event', {
      verb: verb,
      resource: window.location.pathname,
      resourceType: 'page',
      inContext: context,
    });
  };

  let helpdeskStatus = 'default';
  let helpDeskTabOpen = false;

  // Global method to allow opening the helpdesk from static links, e.g. in the footer
  window.openHelpdeskLayer = function () {
    // load helpdesk initially
    if (newSession) {
      load();
      newSession = false;
    }
    helpDeskTabOpen = true;

    track('helpdesk_opened', {});
    $('#helpdesk-panel').show();
    $('#helpdesk-panel__loading').show();
    $('#helpdesk-panel .helpdesk-default-box').show();
    $('#helpdesk-panel .helpdesk-result-box').hide();
  };

  function closeHelpdeskLayer() {
    track('helpdesk_closed', {});

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
