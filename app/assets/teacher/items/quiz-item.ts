import { ExerciseType } from './form-types';
import I18n from '../../i18n/i18n';

const brand = document.documentElement.getAttribute('data-brand') || 'xikolo';

const switchChangeHandler = (target: HTMLInputElement, selector: string) => {
  const element = document.querySelector<HTMLInputElement>(selector);
  element!.hidden = target.checked;
};

const markdownHasDefaultPlaceholders = (markdown: HTMLElement) =>
  // toastUI wraps the default text with a div
  markdown.innerHTML === '<div>[ Enter quiz instructions here ]</div>' ||
  markdown.innerHTML ===
    `<div>${I18n.t('items.quiz.quiz_is_survey', {
      brand,
    })}</div>`;

export const handleQuizExerciseTypes = (quizType: ExerciseType) => {
  const quizInstructionsContainer = document.querySelector(
    '#quiz_instructions_container',
  ) as HTMLElement;
  const quizInstructions = quizInstructionsContainer.querySelector(
    '[contenteditable="true"]',
  ) as HTMLElement;
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
      if (markdownHasDefaultPlaceholders(quizInstructions)) {
        quizInstructions.innerHTML = I18n.t('items.quiz.quiz_is_survey', {
          brand,
        });
      }
      break;
    default:
      unlimitedAttemptsSwitch.checked = true;
      unlimitedTimeSwitch.checked = true;
      allowedAttempts.hidden = true;
      timeLimit.hidden = true;
      quizInstructionsContainer.hidden = true;
      if (quizInstructions) {
        quizInstructions.innerHTML = '[ Enter quiz instructions here ]';
      }
  }
};

export const setTimeAndAttemptsSwitches = () => {
  const unlimitedAttemptsSwitch = document.querySelector(
    '#unlimited-attempts-switch',
  ) as HTMLInputElement;

  const unlimitedTimeSwitch = document.querySelector(
    '#unlimited-time-switch',
  ) as HTMLInputElement;

  unlimitedTimeSwitch.addEventListener('change', (e) => {
    const switcher = e.target as HTMLInputElement;
    switchChangeHandler(switcher, '.xikolo_quiz_quiz_time_limit_seconds');
  });
  unlimitedAttemptsSwitch.addEventListener('change', (e) => {
    const switcher = e.target as HTMLInputElement;
    switchChangeHandler(switcher, '.xikolo_quiz_quiz_allowed_attempts');
  });

  switchChangeHandler(
    unlimitedTimeSwitch,
    '.xikolo_quiz_quiz_time_limit_seconds',
  );
  switchChangeHandler(
    unlimitedAttemptsSwitch,
    '.xikolo_quiz_quiz_allowed_attempts',
  );
};
