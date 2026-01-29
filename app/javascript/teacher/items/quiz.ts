import {
  setVisibility,
  hidePublicDescription,
  hideAndUncheckSwitch,
} from './form-helpers';
import {
  setTimeAndAttemptsSwitches,
  handleQuizExerciseTypes,
} from './quiz-item';
import setQuizQuestions from './quiz-questions';

import { ContentType, ExerciseType, InitState } from './form-types';

const isMainType = (el: ExerciseType) => el === 'main';
const isBonusType = (el: ExerciseType) => el === 'bonus';

const handleProctoring = (exerciseType: ExerciseType, initState: InitState) => {
  const proctoringSwitch =
    document.querySelector<HTMLElement>('#proctoring-switch');
  const proctoringCheckbox = document.querySelector<HTMLInputElement>(
    '#proctoring-checkbox',
  );
  if (!proctoringSwitch || !proctoringCheckbox) return;
  // Display proctoring switch for main and bonus quizzes
  if (
    (isMainType(exerciseType) || isBonusType(exerciseType)) &&
    !proctoringCheckbox.readOnly
  ) {
    proctoringSwitch.hidden = false;
    // Enables the proctoring by default if it was not previously saved as an exam or bonus
    // and the user has now set the item as an exam
    if (initState.isNotProctoringType) {
      proctoringCheckbox.checked = isMainType(exerciseType);
    } else {
      // Set it back to the initial state if it was saved as an exam or bonus quiz
      proctoringCheckbox.checked = initState.proctoring;
    }
  } else {
    proctoringSwitch.hidden = true;
    proctoringCheckbox.checked = false;
  }
};

const listenToExerciseTypeChange = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
  initState: InitState,
) => {
  exerciseTypeElem.addEventListener('change', () => {
    const contentType = contentTypeElem.value as ContentType;
    if (contentType !== 'quiz') return;
    const exerciseType = exerciseTypeElem.value as ExerciseType;
    handleQuizExerciseTypes(exerciseType);
    handleProctoring(exerciseType, initState);
  });
};

const handleQuizType = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
  initState: InitState,
) => {
  setVisibility('show', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_max_points',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
  ]);
  setVisibility('hide', ['#featured-switch', '#icon-type-select']);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hidePublicDescription();
  handleProctoring(exerciseTypeElem.value as ExerciseType, initState);
  setTimeAndAttemptsSwitches();
  setQuizQuestions();

  listenToExerciseTypeChange(contentTypeElem, exerciseTypeElem, initState);
};

export default handleQuizType;
