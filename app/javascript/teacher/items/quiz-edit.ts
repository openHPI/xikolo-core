import handleError from '../../util/error';
import fetch from '../../util/fetch';
import mdupload from '../../util/forms/mdupload';
import { hideLoading, showLoading } from '../../util/loading';
import initMarkdownEditorOnSelector from '../../util/markdown-editor';
import ready from '../../util/ready';
import setScrollMarkers from '../../util/scroll-marker';

/**
 * Fetches form content of provided url and appends it to wrapper element.
 * Initializes markdown editors and upload dropzones.
 *
 * @param wrapper fetched HTML will be appended here
 * @param url
 */
const loadForm = async (wrapper: HTMLElement, url: string) => {
  const wrapperEl = wrapper;

  showLoading();
  try {
    const response = await fetch(url, {});
    const editQuestionHTML = await response.text();
    wrapperEl.innerHTML = editQuestionHTML;
    wrapperEl.style.display = '';

    mdupload.scan(wrapperEl);
    initMarkdownEditorOnSelector(wrapperEl);

    hideLoading();
  } catch (e) {
    handleError(undefined, e);
    hideLoading();
  }
};

const loadEditQuestionForm = async (elem: HTMLElement) => {
  const id = elem.dataset.questionId!;
  const context = elem.closest(`[data-id='${id}']`)!;
  const wrapper = context.querySelector(
    '.edit_form_quiz_wrapper',
  ) as HTMLElement;
  const url = wrapper.dataset.ajaxUrl!;

  loadForm(wrapper, url);
};

const loadEditAnswerForm = async (elem: HTMLElement) => {
  const id = elem.id!;
  const context = elem.closest(`[data-id='${id}']`)!;
  const wrapper = context.querySelector(
    '.edit_form_quiz_question_wrapper',
  ) as HTMLElement;
  const url = elem.dataset.url!;

  loadForm(wrapper, url);
};

const loadAddAnswerForm = async (elem: HTMLElement) => {
  // If the button is clicked twice, we would have a leftover form
  const oldForm = document.querySelector('#new_xikolo_quiz_answer');

  if (oldForm) {
    oldForm.remove();
  }

  const id = elem.id!;
  const context = elem.closest(`[data-id='${id}']`)!;
  const wrapper = context.querySelector(
    '.add_form_quiz_question_wrapper',
  ) as HTMLElement;

  const url = wrapper.dataset.ajaxUrl!;
  loadForm(wrapper, url);
};

ready(() => {
  // Edit question
  document
    .querySelectorAll<HTMLButtonElement>('[data-behavior="edit-quiz-question"]')
    .forEach((button) => {
      button.addEventListener('click', (e) => {
        loadEditQuestionForm(button);
        e.preventDefault();
      });
    });
  setScrollMarkers('[data-behavior="edit-quiz-question"]', 'quiz-edit');

  // Edit answer
  document
    .querySelectorAll<HTMLButtonElement>('[data-behavior="edit-quiz-answer"]')
    .forEach((button) => {
      button.addEventListener('click', () => loadEditAnswerForm(button));
    });
  setScrollMarkers('[data-behavior="edit-quiz-answer"]', 'quiz-edit');

  // Add answer
  document
    .querySelectorAll<HTMLButtonElement>('[data-behavior="add-quiz-answer"]')
    .forEach((button) => {
      button.addEventListener('click', () => loadAddAnswerForm(button));
    });
  setScrollMarkers('[data-behavior="add-quiz-answer"]', 'quiz-edit');
});
