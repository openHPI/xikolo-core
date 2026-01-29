import $ from 'jquery';

export type SharingService = 'facebook' | 'mail';

/**
 * Lanalytics events are emitted via jQuery plugin,
 * which comes with its own event engine.
 * @deprecated
 */
const triggerTrackEvent = (
  verb: string,
  resourceType?: string,
  resource?: string,
  inContext?: SharingService,
) => {
  $(document).trigger('track-event', {
    verb,
    resourceType,
    resource,
    ...(inContext && { service: inContext }),
  });
};

export default triggerTrackEvent;
