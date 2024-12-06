import { initializeTomSelect } from '../../components/global/custom-select';
import initMarkdownEditorOnSelector from '../../util/markdown-editor';
import handleError from '../../util/error';
import fetch from '../../util/fetch';
import mdupload from '../../util/forms/mdupload';
import upload from '../../util/forms/upload';

const initializeForm = (selector: string) => {
  const formElement = document.querySelector(selector) as HTMLFormElement;
  initializeTomSelect(formElement);
  initMarkdownEditorOnSelector(formElement);

  upload.scan(formElement);
  mdupload.scan(formElement);

  formElement.classList.toggle('hidden');
  const cancelButton = formElement.querySelector('.cancel-post');
  cancelButton?.addEventListener('click', () => {
    formElement.classList.toggle('hidden');
  });
};

const loadForm = async (url: string, selector: string) => {
  try {
    const response = await fetch(url!, {});
    const formContent = await response.text();
    const question = document.querySelector(selector)!;

    question.innerHTML = formContent;
    initializeForm(selector);
  } catch (e) {
    handleError(undefined, e);
  }
};

type VoteFormFields = 'votable_id';

const appendVoteFormData = (
  data: FormData,
  key: VoteFormFields,
  value: string,
) => {
  data.append(key, value);
};

type AnswerFields = 'accepted_answer_id' | 'course_id' | 'learning_room_id';

const appendAnswerFormData = (
  data: FormData,
  key: AnswerFields,
  value: string,
) => {
  data.append(key, value);
};

export { loadForm, appendVoteFormData, appendAnswerFormData };
