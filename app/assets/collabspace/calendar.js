import { Calendar } from '@fullcalendar/core';
import daygrid from '@fullcalendar/daygrid';
import timegrid from '@fullcalendar/timegrid';
import interaction from '@fullcalendar/interaction';

import de from '@fullcalendar/core/locales/de';
import fr from '@fullcalendar/core/locales/fr';

import ready from 'util/ready';
import modal from 'util/modal';
import fetch from 'util/fetch';

import './calendar.scss';
import '@fullcalendar/core/main.css';
import '@fullcalendar/daygrid/main.css';
import '@fullcalendar/timegrid/main.css';

ready(() => {
  const el = document.querySelector('#calendar');

  const calendar = new Calendar(el, {
    plugins: [daygrid, timegrid, interaction],
    locales: [de, fr],
    locale: document.documentElement.lang,
    defaultView: 'dayGridMonth',
    allDayDefault: false,

    header: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridMonth,timeGridWeek,timeGridDay',
    },

    eventTimeFormat: {
      hour: 'numeric',
      minute: 'numeric',
      timeZoneName: 'short',
      meridiem: false,
      hour12: false,
    },

    selectable: true,
    editable: true,

    events: (_fetchInfo, successCallback, failureCallback) => {
      (async () => {
        const response = await fetch(el.dataset.eventsUrl, {
          headers: { Accept: 'application/json' },
        });
        return response.json();
      })()
        .then(successCallback)
        .catch(failureCallback);
    },

    select: async (event) => {
      const { start, end } = event;

      const url = new URL(el.dataset.newEventUrl);
      url.searchParams.set('start_time', start.toISOString());
      url.searchParams.set('end_time', end.toISOString());

      await modal(document.querySelector('#calendar-new-event'), url);

      calendar.unselect();
      calendar.refetchEvents();
    },

    eventClick: async ({ event }) => {
      const url = event.extendedProps.edit_url;
      await modal(document.querySelector('#calendar-edit-event'), url);

      calendar.refetchEvents();
    },

    eventDrop: async ({ event }) => {
      await fetch(event.extendedProps.update_url, {
        method: 'PATCH',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          start_time: event.start.toISOString(),
          end_time: event.end.toISOString(),
          all_day: event.allDay,
        }),
      });

      calendar.refetchEvents();
    },
  });
  calendar.render();
});
