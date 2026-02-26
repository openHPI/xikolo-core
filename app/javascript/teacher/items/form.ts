import { initializeTomSelect } from '../../components/global/custom-select';
import initMarkdownEditorOnSelector from '../../util/markdown-editor';
import ready from '../../util/ready';
import { hideAllInputs, setDefaultTypes } from './form-helpers';
import { ContentType } from './form-types';

import mdupload from '../../util/forms/mdupload';
import upload from '../../util/forms/upload';
import handleLtiExerciseType from './lti-exercise';
import handleQuizType from './quiz';
import handleRichTextType from './rich-text';
import handleVideoType from './video';

const appendTemplate = (id: string, parent: HTMLElement) => {
  const template = document.querySelector<HTMLTemplateElement>(id);
  const clonedTemplate = document.importNode(template!.content, true);
  parent.appendChild(clonedTemplate);
};

const toggleContentForm = (contentTypeElem: HTMLInputElement) => {
  const customForm = document.querySelector('#custom-form') as HTMLElement;
  customForm.innerHTML = '';
  appendTemplate(`#${contentTypeElem.value}-form`, customForm);

  initializeTomSelect(customForm);

  upload.scan(customForm);
  mdupload.scan(customForm);
  initMarkdownEditorOnSelector(customForm);
};

const handleFormInputs = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  switch (contentTypeElem.value as ContentType) {
    case 'video':
      handleVideoType();
      break;
    case 'rich_text':
      handleRichTextType();
      break;
    case 'quiz':
      handleQuizType(contentTypeElem, exerciseTypeElem);
      break;
    case 'lti_exercise':
      handleLtiExerciseType(contentTypeElem, exerciseTypeElem);
      break;
    default:
      hideAllInputs();
  }
};

const listenToContentTypeChange = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  contentTypeElem.addEventListener('change', () => {
    toggleContentForm(contentTypeElem);
    handleFormInputs(contentTypeElem, exerciseTypeElem);
    setDefaultTypes(contentTypeElem, exerciseTypeElem);
  });
};

ready(() => {
  const validControllerAction = document.querySelector(
    'body.items-controller.new-action, body.items-controller.edit-action',
  );
  if (!validControllerAction) return;

  const contentTypeElem = document.querySelector(
    '#xikolo_course_item_content_type',
  ) as HTMLInputElement;

  const exerciseTypeElem = document.querySelector(
    '#xikolo_course_item_exercise_type',
  ) as HTMLInputElement;

  handleFormInputs(contentTypeElem, exerciseTypeElem);

  if (validControllerAction.classList.contains('new-action')) {
    listenToContentTypeChange(contentTypeElem, exerciseTypeElem);
  }
});
