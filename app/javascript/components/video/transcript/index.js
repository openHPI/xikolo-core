import Transcript from '../../../components/global/transcript';

const seekingEventType = 'transcript:seeked';

// Buffer notifyCueListChanged events that fire before the player listeners
// are set up. Stencil's init can run before turboReady.
const bufferedCues = new WeakMap();

const notifyCueListChangedHandler = (event) => {
  bufferedCues.set(event.target, event.detail.cues);
};

document.addEventListener('notifyCueListChanged', notifyCueListChangedHandler);

const applyBufferedCues = (player, transcript) => {
  const cues = bufferedCues.get(player);
  if (cues) {
    transcript.fill(cues);
    bufferedCues.delete(player);
  }
  document.removeEventListener(
    'notifyCueListChanged',
    notifyCueListChangedHandler,
  );
};

export const initTranscripts = () => {
  const videosWithTranscript = document.querySelectorAll(
    '[data-videoplayer-with-transcript]',
  );

  videosWithTranscript.forEach((videoWithTranscript) => {
    const player = videoWithTranscript.querySelector('xm-player');
    if (!player) return;

    const transcript = new Transcript(videoWithTranscript);
    applyBufferedCues(player, transcript);

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
};

export default seekingEventType;
