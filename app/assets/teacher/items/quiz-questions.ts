import setScrollMarkers from '../../util/scroll-marker';
import toggleUuids from '../toggle-uuids';
import initMarkdownEditorOnSelector from '../../util/markdown-editor';
import upload from '../../util/forms/upload';
import mdupload from '../../util/forms/mdupload';

const resetQuestionForm = () => {
  const activeQuestionForm = document.querySelector<HTMLElement>(
    '#active-question-form',
  );
  const availableQuestionForms = document.querySelector<HTMLElement>(
    '#available-question-forms',
  );
  const activeQuestionElements = Array.from(
    activeQuestionForm!.children,
  ) as HTMLElement[];

  if (activeQuestionElements.length > 0) {
    [...activeQuestionElements].forEach((element) =>
      availableQuestionForms!.insertAdjacentElement('beforeend', element),
    );
  }
};

const setForm = (formType: HTMLElement) => {
  const activeQuestionForm = document.querySelector<HTMLElement>(
    '#active-question-form',
  );
  resetQuestionForm();
  activeQuestionForm!.appendChild(formType);
};

const toggleGenericFields = (display: string) => {
  const genericFields =
    document.querySelectorAll<HTMLElement>('.generic-fields');
  genericFields.forEach((element) => {
    const el = element;
    el.hidden = display === 'hide';
  });
};

const toggleQuestionForm = (selector: HTMLSelectElement) => {
  const multipleChoiceForm = document.querySelector<HTMLElement>(
    '#multiple-choice-form',
  );
  const multipleAnswerForm = document.querySelector<HTMLElement>(
    '#multiple-answer-form',
  );
  const simpleFreeTextForm = document.querySelector<HTMLElement>(
    '#simple-free-text-form',
  );
  const simpleEssayForm =
    document.querySelector<HTMLElement>('#simple-essay-form');

  toggleGenericFields('show');

  switch (selector.value) {
    case 'multiple_choice':
      setForm(multipleChoiceForm!);
      break;
    case 'multiple_answer':
      setForm(multipleAnswerForm!);
      break;
    case 'free_text':
      setForm(simpleFreeTextForm!);
      break;
    case 'essay':
      setForm(simpleEssayForm!);
      break;
    default:
      toggleGenericFields('hide');
      resetQuestionForm();
  }
};

const setQuestionForm = (quizQuestions: HTMLElement) => {
  const questionTypeSelector = document.querySelector(
    '#meta_question_type',
  ) as HTMLSelectElement;

  toggleQuestionForm(questionTypeSelector);
  questionTypeSelector.addEventListener('change', () =>
    toggleQuestionForm(questionTypeSelector),
  );
  setScrollMarkers('[data-behavior="scroll-marker"]', '_scroll_position');

  upload.scan(quizQuestions);
  mdupload.scan(quizQuestions);
  initMarkdownEditorOnSelector(quizQuestions);
};

const setQuizQuestions = () => {
  const questionsWrapper = document.querySelector<HTMLTemplateElement>(
    '#quiz_questions_wrapper',
  );
  if (!questionsWrapper) return;

  const quizQuestions = document.querySelector(
    '#quiz_questions',
  ) as HTMLElement;
  const clonedTemplate = document.importNode(questionsWrapper.content, true);
  quizQuestions.appendChild(clonedTemplate);
  setQuestionForm(quizQuestions);
  toggleUuids('#toggle_quiz_uuids');
};

export default setQuizQuestions;
