import ready from '../util/ready';
import triggerTrackEvent from '../util/track-event';

ready(() => {
  document
    .getElementById('open-badge-download-button')
    ?.addEventListener('click', () => {
      triggerTrackEvent('downloaded_open_badge', 'course', gon.course_id);
    });
});
