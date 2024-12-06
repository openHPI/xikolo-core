import ready from 'util/ready';
import Transcript from 'components/global/transcript';

const seekingEventType = 'transcript:seeked';

ready(() => {
  const videosWithTranscript = document.querySelectorAll(
    '[data-videoplayer-with-transcript]',
  );

  videosWithTranscript.forEach((videoWithTranscript) => {
    const player = videoWithTranscript.querySelector('xm-player');
    if (!player) return;

    const transcript = new Transcript(videoWithTranscript);

    player.addEventListener(
      'control:changeToggleControlActiveState',
      (event) => {
        const { name, active } = event.detail;
        if (name === 'toggle_transcript') {
          transcript.toggleVisibility(active);
        }
      },
    );

    player.addEventListener('notifyCueListChanged', (event) => {
      const { cues } = event.detail;
      if (cues) {
        transcript.fill(cues);
      } else {
        transcript.displayInfoMessage(true);
      }
    });

    player.addEventListener('notifyActiveCuesUpdated', (event) => {
      const { cues } = event.detail;
      if (cues) {
        transcript.updateActiveCues(cues);
      }
    });

    transcript.element.addEventListener(seekingEventType, (event) => {
      const { seconds } = event.detail;

      player.seek(Number(seconds));
    });
  });
});

export default seekingEventType;
