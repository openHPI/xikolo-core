import I18n from '../../i18n/i18n';
import handleError from '../../util/error';
import fetch from '../../util/fetch';
import { turboReady } from '../../util/ready';
import { appendAnswerFormData } from './util';

const acceptAnswer = async (el: HTMLElement) => {
  const { questionId, answerId, courseId } = el.dataset;
  el.remove();

  const data = new FormData();
  appendAnswerFormData(data, 'accepted_answer_id', answerId!);
  appendAnswerFormData(data, 'course_id', courseId!);

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

turboReady(() => {
  document.querySelectorAll<HTMLElement>('.accept').forEach((acceptTrigger) => {
    acceptTrigger.addEventListener('click', () => acceptAnswer(acceptTrigger));
  });
});
