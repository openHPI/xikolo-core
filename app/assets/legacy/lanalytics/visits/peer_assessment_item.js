/* eslint-disable */

import ready from 'util/ready';

ready(function () {
  if (gon.user_id != null && !gon.in_app) {
    $(document).trigger('track-event', {
      verb: 'visited_item',
      resource: gon.item_id,
      resourceType: 'item',
      inContext: {
        course_id: gon.course_id,
        section_id: gon.section_id,
      },
    });
  }
});
