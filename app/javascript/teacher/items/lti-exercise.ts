import {
  setVisibility,
  hidePublicDescription,
  hideAndUncheckSwitch,
} from './form-helpers';
import { ContentType, ExerciseType } from './form-types';

const handleMaxPoints = (exerciseType: ExerciseType) => {
  const maxPoints = document.querySelector<HTMLElement>(
    '.xikolo_course_item_max_points',
  );
  const maxPointsField = document.querySelector<HTMLInputElement>(
    '#xikolo_course_item_max_points',
  );
  if (!maxPoints || !maxPointsField) return;
  // LTI exercises from type none do not grant points.
  // We make sure the value is set to 0 and we hide the field.

  if (exerciseType === '') {
    maxPointsField.value = '0';
    maxPoints.hidden = true;
  } else {
    if (maxPointsField.value === '0') {
      maxPointsField.value = '';
    }
    maxPoints.hidden = false;
  }
};

const listenToExerciseTypeChange = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  exerciseTypeElem.addEventListener('change', () => {
    const contentType = contentTypeElem.value as ContentType;
    if (contentType !== 'lti_exercise') return;
    const exerciseType = exerciseTypeElem.value as ExerciseType;
    handleMaxPoints(exerciseType);
  });
};

const handleLtiExerciseType = (
  contentTypeElem: HTMLInputElement,
  exerciseTypeElem: HTMLInputElement,
) => {
  setVisibility('show', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
  ]);
  setVisibility('hide', ['#featured-switch', '#icon-type-select']);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hideAndUncheckSwitch('#proctoring-switch', '#proctoring-checkbox');
  hidePublicDescription();
  handleMaxPoints(exerciseTypeElem.value as ExerciseType);
  listenToExerciseTypeChange(contentTypeElem, exerciseTypeElem);
};

export default handleLtiExerciseType;
