import type { ToggleControlProps } from '@openhpi/xikolo-video-player/dist/types/utils/types';
import type {
  XmControlsCustomEvent,
  XmSettingsMenuCustomEvent,
} from '@openhpi/xikolo-video-player/dist/types/components';
import fetch from '../../../util/fetch';

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
  try {
    const formData = new FormData();
    formData.append('name', preference);
    formData.append('value', value);

    const response = await fetch('/preferences', {
      method: 'PUT',
      body: formData,
    });

    // Guest user: preference cannot be stored, silently ignore.
    if (response.status === 401 || response.status === 403) return;

    if (!response.ok) {
      throw new Error(response.statusText);
    }
  } catch (error) {
    console.error('Error saving preferences:', error);
  }
};

export const initPreferenceAdapter = () => {
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
};
