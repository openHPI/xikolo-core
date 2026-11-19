import { ExerciseType } from './form-types';
import I18n from '../../i18n/i18n';

const switchChangeHandler = (
  target: HTMLInputElement | undefined,
  selector: string,
) => {
  if (!target) return;
  const element = document.querySelector<HTMLInputElement>(selector);
  if (element) element.hidden = target.checked;
};

const markdownHasDefaultPlaceholders = (markdown: HTMLElement) =>
  // toastUI wraps the default text with a div
  markdown.innerHTML === '<div>[ Enter quiz instructions here ]</div>' ||
  markdown.innerHTML === `<div>${I18n.t('items.quiz.quiz_is_survey')}</div>`;

export const handleQuizExerciseTypes = (quizType: ExerciseType) => {
  const quizInstructionsContainer = document.querySelector(
    '#quiz_instructions_container',
  ) as HTMLElement;
  const quizInstructions = quizInstructionsContainer.querySelector(
    '[contenteditable="true"]',
  ) as HTMLElement;
  const quizInstructionsInput = quizInstructionsContainer.querySelector(
    '[data-behavior="markdown-form-input"]',
  ) as HTMLTextAreaElement;
  const setInstructionsRequired = (required: boolean) => {
    // The instructions field is hidden for some exercise types (e.g. self
    // tests). A `required` control that is hidden cannot be focused, so the
    // browser blocks submission ("not focusable"). Keep `required` in sync
    // with visibility to avoid this.
    if (quizInstructionsInput) quizInstructionsInput.required = required;
  };
  const unlimitedTimeSwitch = document.querySelector(
    '#unlimited-time-switch',
  ) as HTMLInputElement;
  const unlimitedAttemptsSwitch = document.querySelector(
    '#unlimited-attempts-switch',
  ) as HTMLInputElement;
  const allowedAttempts = document.querySelector(
    '.xikolo_quiz_quiz_allowed_attempts',
  ) as HTMLInputElement;
  const timeLimit = document.querySelector(
    '.xikolo_quiz_quiz_time_limit_seconds',
  ) as HTMLInputElement;
  switch (quizType) {
    case 'main':
    case 'bonus':
      unlimitedAttemptsSwitch.checked = false;
      unlimitedTimeSwitch.checked = false;
      allowedAttempts.hidden = false;
      timeLimit.hidden = false;
      quizInstructionsContainer.hidden = false;
      setInstructionsRequired(true);
      if (markdownHasDefaultPlaceholders(quizInstructions)) {
        quizInstructions.innerHTML = '[ Enter quiz instructions here ]';
      }
      break;
    case 'survey':
      unlimitedAttemptsSwitch.checked = false;
      unlimitedTimeSwitch.checked = true;
      allowedAttempts.hidden = false;
      timeLimit.hidden = true;
      quizInstructionsContainer.hidden = false;
      setInstructionsRequired(true);
      if (markdownHasDefaultPlaceholders(quizInstructions)) {
        quizInstructions.innerHTML = I18n.t('items.quiz.quiz_is_survey');
      }
      break;
    default:
      unlimitedAttemptsSwitch.checked = true;
      unlimitedTimeSwitch.checked = true;
      allowedAttempts.hidden = true;
      timeLimit.hidden = true;
      quizInstructionsContainer.hidden = true;
      setInstructionsRequired(false);
      if (quizInstructions) {
        quizInstructions.innerHTML = '[ Enter quiz instructions here ]';
      }
  }
};

export const setTimeAndAttemptsSwitches = () => {
  const unlimitedAttemptsSwitch = document.querySelector<HTMLInputElement>(
    '#unlimited-attempts-switch',
  );

  const unlimitedTimeSwitch = document.querySelector<HTMLInputElement>(
    '#unlimited-time-switch',
  );

  // Exams always time-limit the quiz and fix the number of attempts, so the
  // corresponding switches are absent from the form.
  if (unlimitedTimeSwitch) {
    unlimitedTimeSwitch.addEventListener('change', (e) => {
      switchChangeHandler(
        e.target as HTMLInputElement,
        '.xikolo_quiz_quiz_time_limit_seconds',
      );
    });
  }
  if (unlimitedAttemptsSwitch) {
    unlimitedAttemptsSwitch.addEventListener('change', (e) => {
      switchChangeHandler(
        e.target as HTMLInputElement,
        '.xikolo_quiz_quiz_allowed_attempts',
      );
    });
  }

  switchChangeHandler(
    unlimitedTimeSwitch ?? undefined,
    '.xikolo_quiz_quiz_time_limit_seconds',
  );
  switchChangeHandler(
    unlimitedAttemptsSwitch ?? undefined,
    '.xikolo_quiz_quiz_allowed_attempts',
  );
};
