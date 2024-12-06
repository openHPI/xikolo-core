import ready from '../util/ready';
import triggerTrackEvent, { SharingService } from '../util/track-event';

ready(() => {
  document.querySelectorAll('a[data-sharing-service]').forEach((l) => {
    l.addEventListener('click', () => {
      const link = l as HTMLAnchorElement;

      const verb = link.dataset.trackingVerb;
      const service = link.dataset.sharingService as SharingService;

      if (gon.course_id) {
        triggerTrackEvent(verb!, 'course', gon.course_id, service);
      }
    });
  });
});
