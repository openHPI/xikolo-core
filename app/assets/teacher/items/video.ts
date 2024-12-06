import { setVisibility, hideAndUncheckSwitch } from './form-helpers';
import videoStreamsAutocompletion from './video-streams';

const handlePublicDescription = () => {
  const publicDescription = document.querySelector(
    '#public-description-markdown',
  ) as HTMLElement;
  const openModeCheckbox = document.querySelector(
    '#open-mode-checkbox',
  ) as HTMLInputElement;
  publicDescription.hidden = !openModeCheckbox.checked;
};

const listenToOpenModeChange = (openModeSwitch: HTMLElement) => {
  openModeSwitch.addEventListener('change', () => {
    handlePublicDescription();
  });
};

const handleOpenMode = () => {
  const openModeSwitch =
    document.querySelector<HTMLElement>('#open-mode-switch');
  if (openModeSwitch) {
    listenToOpenModeChange(openModeSwitch);
    openModeSwitch.hidden = false;
    handlePublicDescription();
  }
};

const handleVideoType = () => {
  setVisibility('hide', [
    '.xikolo_course_item_exercise_type',
    '.xikolo_course_item_max_points',
    '.xikolo_course_item_submission_deadline',
    '.xikolo_course_item_submission_publishing_date',
    '#icon-type-select',
  ]);
  setVisibility('show', ['#featured-switch']);
  hideAndUncheckSwitch('#proctoring-switch', '#proctoring-checkbox');
  handleOpenMode();
  videoStreamsAutocompletion();
};

export default handleVideoType;
