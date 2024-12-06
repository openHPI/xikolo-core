ready(function () {
  var newSession = true;
  // Generate a new "session" identifier so that we can relate tracking events to each other
  var helpdeskSession = Math.random().toString(36).substr(2, 12);

  var enforceMinimumDelay = function (minDelay, timePassed, index, callback) {
    var delay = Math.max(0, minDelay - timePassed);

    setTimeout(callback, delay * (index + 1));
  };

  var load = function (helpdeskType = '') {
    $('#helpdesk-ajax-container').load(helpdeskURL(helpdeskType), function () {
      if ($('#course_id_container').text()) {
        $('select#category').val($('#course_id_container').text()).change();
      }

      prototype2();

      $('#helpdesk-panel__loading').hide();

      document
        .querySelector('.helpdesk-closing-button')
        .addEventListener('click', closeHelpdeskLayer);

      window.initTabNavigation();

      if (checkboxRecaptcha(helpdeskType)) {
        openHelpdeskTab();
      }

      $(`#helpdesk-form${helpdeskType}`).on('submit', function () {
        var { report, title, category, topic, mail } = getFormParams();

        var url = document.URL,
          userAgent = navigator.userAgent,
          language = navigator.language,
          cookieEnabled = navigator.cookieEnabled,
          recaptcha_token_v2 = checkboxRecaptcha(helpdeskType)
            ? grecaptcha.getResponse()
            : null,
          recaptcha_token_v3 = $(
            'input#g-recaptcha-response-data-helpdesk',
          ).val();

        $.ajax({
          type: 'POST',
          url: '/helpdesk/',
          dataType: 'html',
          data: {
            report: report,
            url: url,
            topic: topic,
            userAgent: userAgent,
            language: language,
            category: category,
            cookie: cookieEnabled,
            title: title,
            mail: mail,
            ...(recaptcha_token_v2
              ? { recaptcha_token_v2: recaptcha_token_v2 }
              : {}),
            ...(recaptcha_token_v3
              ? { recaptcha_token_v3: recaptcha_token_v3 }
              : {}),
          },
        })
          .fail(function (jqXHR) {
            fadeInResult();
            $('#helpdesk-panel .helpdesk-result-box').html(jqXHR.responseText);
            helpdeskStatus = 'error';
          })
          .done(function (response) {
            $('#helpdesk-panel .helpdesk-result-box').html(response);

            if (response.includes('checkbox_recaptcha')) {
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

              $('#issuereport').val('');
              $('#issuetitle').val('');

              track('helpdesk_ticket_created', {
                report: report,
                topic: category,
                question: title,
              });
            }
          });
        return false;
      });
    });
  };

  var helpdeskURL = function (helpdeskType) {
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

  var checkboxRecaptcha = function (helpdeskType) {
    return helpdeskType == '-with-checkbox-recaptcha';
  };

  var getFormParams = function () {
    return (params = {
      report: $('#issuereport').val(),
      title: $('#issuetitle').val(),
      category: $('#category').val(),
      topic: $("input[name='question_topic']:checked").val(),
      mail: $('#issueemail').val(),
    });
  };

  var fadeInResult = function () {
    $('#helpdesk-panel .helpdesk-default-box').fadeOut('slow', function () {
      $('#helpdesk-panel .helpdesk-result-box').fadeIn('slow');
    });
  };

  const openHelpdeskTab = () =>
    document.querySelector('[aria-controls="chatbot-panel-2"]')?.click();

  var track = function (verb, context) {
    // We currently cannot track events for guest users
    if (!gon.user_id) return;

    var featureContainer = document.getElementById('chatbot-current-feature');

    context['helpdesk_session_id'] = helpdeskSession;
    context['chatbot_version'] = featureContainer
      ? featureContainer.dataset.feature
      : 'default';
    context['language'] = I18n.locale;

    $(document).trigger('track-event', {
      verb: verb,
      resource: window.location.pathname,
      resourceType: 'page',
      inContext: context,
    });
  };

  // Set up the chatbot
  var prototype2 = function () {
    var conversation = document.getElementById('chatbot-conversation');
    if (!conversation) return;

    new Chatbot(conversation);
  };

  var helpdeskStatus = 'default';
  var helpDeskTabOpen = false;

  // Global method to allow opening the helpdesk from static links, e.g. in the footer
  window.openHelpdeskLayer = function () {
    // load helpdesk and chatbot initially
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

  function Chatbot(element) {
    this.conversation$ = element;
    this.$input = $('#chatbot-typing-area');
    this.$sendButton = $('#chatbot-enter-btn');

    this.loading = false;

    this.listen();

    // Greet the user and place their cursor in the chat window so they can start typing
    this.$input.focus();
    this.greet();
  }

  Chatbot.prototype = {
    listen: function () {
      var bot = this;

      // Send text input to the chatbot on key input "Enter" and by clicking on the "Enter" button
      this.$sendButton.on('click', function (e) {
        e.preventDefault(); // Do not submit surrounding form

        bot.handleInput();
      });
    },

    handleInput: function (payload, initialize) {
      var startTime = new Date().getTime();
      var question = this.$input.val();
      var url = getUrlFromConfig('chatbot-urls-v2');
      var token =
        document.getElementById('chatbot-api-token').dataset.chatbotToken;

      this.$input.val('');

      if (initialize) {
        question = I18n.t('chatbot.hello');
      } else {
        this.addUtterance(question, 'chatbot-question');
        this.startLoading();
      }

      var bot = this;

      if (payload && payload != null) {
        question = payload;
      }

      $.ajax({
        type: 'POST',
        url: url,
        dataType: 'json',
        data: JSON.stringify({ message: question, sender: token }),
        complete: function (xhr, status) {
          var requestTime = new Date().getTime() - startTime;
          var trackingContext = {
            question: question,
            request_time: requestTime,
            status: status,
          };

          if (status.startsWith('success')) {
            var response = $.parseJSON(xhr.responseText);
            trackingContext['response'] = response;
            bot.handleResponse(response, requestTime);
          } else {
            bot.stopLoading();
          }

          bot.$input.focus();
          bot.conversation$.scrollTop = bot.conversation$.scrollHeight;

          track('helpdesk_chatbot_replied', trackingContext);
        },
      });
    },

    handleResponse: function (response, requestTime) {
      if (response.length === 0) return;

      var bot = this;
      var responseCount = response.length;

      response.forEach(function (answer, index) {
        enforceMinimumDelay(1000, requestTime, index, function () {
          if (answer.custom) {
            answer.buttons = answer.custom.buttons;
          }
          if (answer.text) {
            bot.stopLoading();
            bot.addUtterance(answer.text, 'chatbot-answer');
          }
          if (answer.buttons) {
            $('#chatbot-typing-area').prop('disabled', true);
            $('#chatbot-enter-btn').prop('disabled', true);
            var buttons = answer.buttons;
            buttons.forEach(function (button, index) {
              enforceMinimumDelay(500, requestTime, index, function () {
                bot.stopLoading();
                bot.addButtonUtterance(button.title, button.payload);
              });
            });
          }
          if (answer.custom) {
            const delayIndex = answer.buttons.length;
            enforceMinimumDelay(500, requestTime, delayIndex, () => {
              bot.stopLoading();
              bot.addButtonUtterance(I18n.t('chatbot.own_message'), null);
            });
          }
          bot.startLoading();
          responseCount--;
          if (responseCount <= 1) bot.stopLoading();
        });
      });
    },

    startLoading: function () {
      this.loading = true;
      this.conversation$.dataset['loading'] = 'true';
      this.conversation$.scrollTop = this.conversation$.scrollHeight;
    },

    stopLoading: function () {
      this.loading = false;
      this.conversation$.dataset['loading'] = 'false';
    },

    greet: function () {
      this.handleInput(null, true);
    },

    addUtterance: function (utterance, type) {
      var message = document.createElement('div');
      message.classList.add('chatbot-message-box', type);
      message.innerHTML = utterance.trim();

      this.conversation$.insertBefore(
        message,
        document.getElementById('utterance--placeholder'),
      );
      this.conversation$.scrollTop = this.conversation$.scrollHeight;
    },

    addButtonUtterance: function (utterance, payload) {
      var bot = this;
      var button = document.createElement('button');
      button.type = 'button';
      button.classList.add(
        'chatbot-message-box',
        'chatbot-answer',
        'chatbot-button-answer',
      );
      button.innerHTML = utterance.trim();
      button.onclick = function () {
        if (payload == null) {
          bot.addUtterance(utterance, 'chatbot-question');
          bot.addUtterance(
            I18n.t('chatbot.own_message_note'),
            'chatbot-answer',
          );
        } else {
          $('#chatbot-typing-area').val(utterance.trim());
          bot.handleInput(payload);
        }
        $('.chatbot-button-answer').remove();
        $('#chatbot-typing-area').prop('disabled', false);
        $('#chatbot-enter-btn').prop('disabled', false);
      };

      this.conversation$.insertBefore(
        button,
        document.getElementById('utterance--placeholder'),
      );
      this.conversation$.scrollTop = this.conversation$.scrollHeight;
    },
  };

  function getUrlFromConfig(id) {
    var urlContainer = document.getElementById(id);
    var url = urlContainer.dataset.userChatbotUrl;
    return url;
  }

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
      openHelpdeskLayer();
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

  if ($('#helpdesk-form-with-checkbox-recaptcha').length) {
    openHelpdeskTab();
  }

  // Initialize the chatbot prototype if it's already rendered on the page
  prototype2();
});
