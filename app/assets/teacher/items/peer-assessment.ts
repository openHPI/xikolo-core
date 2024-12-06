import {
  setVisibility,
  hidePublicDescription,
  hideAndUncheckSwitch,
} from './form-helpers';

const handlePeerAssessmentType = () => {
  setVisibility('hide', [
    '.xikolo_course_item_max_points',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
    '#featured-switch',
    '#icon-type-select',
  ]);
  setVisibility('show', ['.xikolo_course_item_exercise_type']);
  hideAndUncheckSwitch('#open-mode-switch', '#open-mode-checkbox');
  hideAndUncheckSwitch('#proctoring-switch', '#proctoring-checkbox');
  hidePublicDescription();
};

export default handlePeerAssessmentType;
