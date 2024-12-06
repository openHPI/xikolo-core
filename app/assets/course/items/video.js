import ready from 'util/ready';

const addTimestampListener = (timestamp, player, seconds) => {
  timestamp.addEventListener('click', () => {
    player.seek(seconds);
    player.scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
};

const topicCreationLogic = () => {
  const btnShowQuestion = document.querySelector('#show-topic-form');
  const topicForm = document.querySelector('#topic-form');

  // Skip all of this if the required topic form and button are not available,
  // i.e. when the forum is locked.
  if (!topicForm || !btnShowQuestion) return;

  const formElement = topicForm.querySelector('form');
  const btnTopicFormCancel = topicForm.querySelector('.js-cancel-topic');

  btnShowQuestion.addEventListener('click', () => {
    if (!topicForm) return;

    btnShowQuestion.hidden = true;
    topicForm.hidden = false;
  });

  btnTopicFormCancel.addEventListener('click', () => {
    if (!topicForm) return;

    topicForm.hidden = true;
    btnShowQuestion.hidden = false;
    formElement.reset();
  });

  const createTopic = async (url, data) =>
    fetch(url, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: JSON.stringify(data),
    });

  const handleSubmit = async (event) => {
    event.preventDefault();

    // Fetch video timestamp and update topic form accordingly
    const videoPlayer = document.querySelector('xm-player');
    const inputVideoTimestamp = formElement.elements['topic[video_timestamp]'];
    if (videoPlayer) {
      const progress = await videoPlayer.getProgress();

      inputVideoTimestamp.value = Math.floor(progress);
    }

    // Create topic
    try {
      const response = await createTopic(formElement.action, {
        topic: {
          title: formElement.elements['topic[title]'].value,
          text: formElement.elements['topic[text]'].value,
          video_timestamp: formElement.elements['topic[video_timestamp]'].value,
        },
      });

      const json = await response.json();

      // Remove possible prior error message
      const errorNotification = formElement.querySelector(
        '.error_notification',
      );
      if (errorNotification) errorNotification.remove();

      // Handle creation errors
      if (!response.ok) {
        const newError = document.createElement('p');
        newError.classList.add('error_notification');
        newError.innerText = Object.values(json.errors).flat().join(' ');
        formElement.prepend(newError);
        return;
      }

      // Create topic element from template and prepend it to the list
      const template = document.getElementById('new-topic');
      const newTopic = template.content.cloneNode(true);
      newTopic.querySelector('.topic__title > h5').innerText = json.title;
      const timeStamp = newTopic.querySelector('.topic__timestamp');
      timeStamp.innerText = I18n.t('items.show.video.timestamp', {
        time: json.timestamp,
      });
      addTimestampListener(timeStamp, videoPlayer, inputVideoTimestamp.value);
      newTopic.querySelector('.wmd-output.topic__abstract').innerHTML =
        json.abstract;
      newTopic.querySelector('.topic__url > a').setAttribute('href', json.url);

      const topicList = document.querySelector(
        '[data-slider-target="content"]',
      );
      const sliderIntersector = topicList.querySelector(
        "[data-slider-target='intersector-right']",
      );
      topicList.insertBefore(newTopic, sliderIntersector);

      // Reset and hide the form
      formElement.reset();
      topicForm.hidden = true;
      btnShowQuestion.hidden = false;

      // Remove empty state or update topic count
      const emptyStateMessage = document.querySelector(
        '[data-topic-empty-state]',
      );
      const topicCount = document.querySelector('[data-topic-count] > p');
      if (emptyStateMessage) {
        emptyStateMessage.remove();
      } else if (topicCount) {
        const count = topicCount.textContent.match(/\d+/);
        topicCount.innerText = topicCount.textContent.replace(
          /\d+/,
          Number(count) + 1,
        );
      }
    } catch {
      const newError = document.createElement('p');
      newError.classList.add('error_notification');
      newError.innerText = I18n.t('errors.messages.topic.base.not_created');
      formElement.prepend(newError);
    }
  };

  formElement.addEventListener('submit', (event) => handleSubmit(event));
};

const topicTimestampLogic = () => {
  const videoPlayer = document.querySelector('xm-player');
  if (!videoPlayer) return;
  document.querySelectorAll('[data-seek-timestamp]').forEach((timestamp) => {
    addTimestampListener(
      timestamp,
      videoPlayer,
      timestamp.dataset.seekTimestamp,
    );
  });
};

/**
 * Attaches logic to the document.body to forward certain Keyboard events to the video player
 * When the body has the focus, functions on the player will be called
 */
const forwardShortcutKeysToPlayer = async () => {
  // There is a weird behavior in chrome:
  // Sometimes methods of the public are not available
  // To have reliable access, the script waits for the component to be defined completely
  await customElements.whenDefined('xm-player');

  const videoPlayer = document.querySelector('xm-player');
  if (!videoPlayer) return;

  // Filter out arrow navigation keys from shortcuts
  let shortCutKeys = await videoPlayer.getShortcutKeys();
  shortCutKeys = shortCutKeys.filter(
    (key) => key !== 'ArrowUp' && key !== 'ArrowDown',
  );

  document.body.addEventListener('keydown', (e) => {
    // The check for the tag name makes sure that the user can e.g. type in an input
    if (e.target.tagName === 'BODY' && shortCutKeys.includes(e.key)) {
      const player = document.querySelector('xm-player');
      player.dispatchEvent(new KeyboardEvent('keydown', e));

      // Prevent scrolling with space bar for play / pause
      if (e.key === ' ') {
        e.preventDefault();
      }
    }
  });
};

ready(async () => {
  topicCreationLogic();
  topicTimestampLogic();
  await forwardShortcutKeysToPlayer();
});
