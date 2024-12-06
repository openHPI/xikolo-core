import { ToggleControlProps } from '@openhpi/xikolo-video-player/dist/types/utils/types';
import {
  XmControlsCustomEvent,
  XmSettingsMenuCustomEvent,
} from '@openhpi/xikolo-video-player/dist/types/components';
import ready from '../../util/ready';
import fetch from '../../util/fetch';

declare global {
  interface HTMLElementEventMap {
    'control:changeToggleControlActiveState': XmControlsCustomEvent<ToggleControlProps>;
    'setting:changePlaybackRate': XmControlsCustomEvent<{
      playbackRate: string;
    }>;
    'control:changePlaybackRate': XmControlsCustomEvent<{
      playbackRate: string;
    }>;
    'setting:changeTextTrack': XmSettingsMenuCustomEvent<{ textTrack: string }>;
  }
}

const savePreference = async (preference: string, value: string) => {
  const userId = gon.user_id;

  // We cannot save the preference if there is no user
  if (!userId) return;

  try {
    const formData = new FormData();
    formData.append('name', preference);
    formData.append('value', value);

    const response = await fetch('/preferences', {
      method: 'PUT',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(response.statusText);
    }
  } catch (error) {
    console.error('Error saving preferences:', error);
  }
};

ready(() => {
  document.querySelectorAll('xm-player').forEach((player) => {
    player.addEventListener('setting:changePlaybackRate', (event) => {
      const { playbackRate } = event.detail;
      savePreference('ui.video.video_player_speed', playbackRate);
    });

    player.addEventListener('control:changePlaybackRate', (event) => {
      const { playbackRate } = event.detail;
      savePreference('ui.video.video_player_speed', playbackRate);
    });

    player.addEventListener('setting:changeTextTrack', (event) => {
      if (event.detail.textTrack !== 'off') {
        savePreference(
          'ui.video.video_player_caption_language',
          event.detail.textTrack,
        );
      }
    });

    player.addEventListener('control:enableTextTrack', () =>
      savePreference('ui.video.video_player_show_captions', 'true'),
    );

    player.addEventListener('control:disableTextTrack', () =>
      savePreference('ui.video.video_player_show_captions', 'false'),
    );

    player.addEventListener(
      'control:changeToggleControlActiveState',
      (event) => {
        const { name, active } = event.detail;
        if (name === 'toggle_transcript') {
          savePreference(
            'ui.video.video_player_show_transcript',
            active.toString(),
          );
        }
      },
    );
  });
});
