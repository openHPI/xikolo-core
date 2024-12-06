import handleError from '../../util/error';
import fetch from '../../util/fetch';
import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';
import { loadForm, appendAnswerFormData } from './util';

const loadAnswerForm = (el: HTMLElement) => {
  const { answerId, url } = el.dataset;

  loadForm(url!, `#answer-edit-${answerId}`);

  triggerTrackEvent('clicked_edit_answer', 'answer', answerId);
};

const acceptAnswer = async (el: HTMLElement) => {
  const { questionId, answerId, courseId, learningRoomId } = el.dataset;
  el.remove();

  const data = new FormData();
  appendAnswerFormData(data, 'accepted_answer_id', answerId!);
  appendAnswerFormData(data, 'course_id', courseId!);
  appendAnswerFormData(data, 'learning_room_id', learningRoomId!);

  try {
    await fetch(`${questionId}/accept_answer`, {
      method: 'POST',
      body: data,
    });

    window.location.reload();
  } catch (error) {
    handleError(I18n.t('pinboard.errors.loading'), error);
  }

  // Return false so that the link's default action is not fired
  return false;
};

ready(() => {
  document
    .querySelectorAll<HTMLElement>('.answer-edit')
    .forEach((answerEditEl) => {
      answerEditEl.addEventListener('click', () =>
        loadAnswerForm(answerEditEl),
      );
    });

  document.querySelectorAll<HTMLElement>('.accept').forEach((acceptTrigger) => {
    acceptTrigger.addEventListener('click', () => acceptAnswer(acceptTrigger));
  });
});
