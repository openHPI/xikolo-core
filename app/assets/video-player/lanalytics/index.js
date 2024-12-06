import ready from 'util/ready';
import PlayerTracker from './player-tracker';
import seekingEventType from '../transcript';

ready(() => {
  document.querySelectorAll('xm-player').forEach((player) => {
    const tracker = new PlayerTracker();

    player.addEventListener('play', (event) =>
      tracker.trackTime('video_play', event.detail.seconds),
    );
    player.addEventListener('pause', (event) =>
      tracker.trackTime('video_pause', event.detail.seconds),
    );
    player.addEventListener('ended', (event) =>
      tracker.trackTime('video_end', event.detail.seconds),
    );
    player.addEventListener('seeked', (event) =>
      tracker.trackTimeWhileSeeking('video_seek', event.detail.seconds),
    );
    player.addEventListener('timeupdate', (event) =>
      tracker.updateTime(event.detail.seconds),
    );

    player.addEventListener('setting:changePlaybackRate', (event) =>
      tracker.trackProperty(
        'video_change_speed',
        'newSpeed',
        'currentSpeed',
        event.detail.playbackRate,
      ),
    );
    player.addEventListener('control:enterFullscreen', () =>
      tracker.trackProperty(
        'video_fullscreen',
        'newCurrentFullscreen',
        'currentFullscreen',
        true,
      ),
    );
    player.addEventListener('control:exitFullscreen', () =>
      tracker.trackProperty(
        'video_fullscreen',
        'newCurrentFullscreen',
        'currentFullscreen',
        false,
      ),
    );

    player.addEventListener('setting:changeTextTrack', (event) => {
      // TODO: XI-5130: Track user events with lanalytics for toggling the short-cut button for subtitles
      PlayerTracker.trackEvent('video_subtitle', {
        ...tracker.playerState,
        newSubtitleLanguage: event.detail.textTrack,
      });
      if (
        tracker.privatePlayerState.isTranscriptActive &&
        event.detail.textTrack !== 'off'
      ) {
        PlayerTracker.trackEvent('video_transcript', {
          ...tracker.playerState,
          newTranscriptLanguage: event.detail.textTrack,
        });
      }
    });

    player.addEventListener(
      'control:changeToggleControlActiveState',
      (event) => {
        const { name, active } = event.detail;
        if (name === 'toggle_transcript') {
          /**
           * At the moment we have no public access to the language information,
           * so we sneaked into the controls and just get it from there #workaround.
           * That could be changed after doing this:
           * -> XI-4988- Video Player: Language Selection Control Toolbar Button
           */
          const currentLanguage =
            player.shadowRoot.querySelector('xm-controls').status.subtitle
              .language;
          // Save the active state for tracking the "setting:changeTextTrack" event.
          tracker.privatePlayerState.isTranscriptActive = active;

          /**
           * Add the current language information if it is active or use 'off'
           * (for consistency with legacy data).
           */
          PlayerTracker.trackEvent('video_transcript', {
            ...tracker.playerState,
            newTranscriptLanguage: active ? currentLanguage : 'off',
          });
        }
      },
    );

    window.addEventListener('unload', () => {
      PlayerTracker.trackEvent('video_close', { ...tracker.playerState });
    });

    // Transcript event listeners
    const transcript = player.parentElement.querySelector('[data-transcript]');
    if (!transcript) return;

    transcript.addEventListener(seekingEventType, (event) => {
      tracker.trackTimeWhileSeeking(
        'video_transcript_seek',
        event.detail.seconds,
      );
    });
  });
});
