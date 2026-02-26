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

import { ContentType, ExerciseType } from './form-types';

const listenToExerciseTypeChange = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  exerciseTypeElem.addEventListener('change', () => {
    const contentType = contentTypeElem.value as ContentType;
    if (contentType !== 'quiz') return;
    const exerciseType = exerciseTypeElem.value as ExerciseType;
    handleQuizExerciseTypes(exerciseType);
  });
};

const handleQuizType = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
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
  setTimeAndAttemptsSwitches();
  setQuizQuestions();

  listenToExerciseTypeChange(contentTypeElem, exerciseTypeElem);
};

export default handleQuizType;
