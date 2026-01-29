import ready from '../../util/ready';
import triggerTrackEvent from '../../util/track-event';
import { loadForm } from './util';

const loadQuestionForm = async (el: HTMLElement) => {
  const { questionId, url } = el.dataset;

  loadForm(url!, `#question-edit-${questionId}`);
  triggerTrackEvent('clicked_edit_question', 'question', questionId);
};

ready(() => {
  document
    .querySelectorAll<HTMLElement>('.question-edit')
    .forEach((questionEditEl) => {
      questionEditEl.addEventListener('click', () =>
        loadQuestionForm(questionEditEl),
      );
    });
});
