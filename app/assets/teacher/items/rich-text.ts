import {
  setVisibility,
  hidePublicDescription,
  hideAndUncheckSwitch,
} from './form-helpers';

const handleRichTextType = () => {
  setVisibility('hide', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_max_points',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
    '#featured-switch',
  ]);
  setVisibility('show', ['#icon-type-select']);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hideAndUncheckSwitch('#proctoring-switch', '#proctoring-checkbox');
  hidePublicDescription();
};

export default handleRichTextType;
