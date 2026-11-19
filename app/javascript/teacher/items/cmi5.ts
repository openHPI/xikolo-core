import {
  setVisibility,
  hidePublicDescription,
  hideAndUncheckSwitch,
} from './form-helpers';

const handleCmi5Type = (exerciseTypeElem: HTMLInputElement) => {
  exerciseTypeElem.value = 'selftest';

  setVisibility('show', ['.xikolo_course_item_max_points']);
  setVisibility('hide', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
    '#icon-type-select',
  ]);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hidePublicDescription();
};

export default handleCmi5Type;
