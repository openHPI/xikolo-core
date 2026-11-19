import { turboReady } from '../../util/ready';

let videoPlayerLoaded = null;

const loadVideoPlayer = async () => {
  if (!document.querySelector('xm-player')) return;

  if (videoPlayerLoaded) return videoPlayerLoaded;

  videoPlayerLoaded = (async () => {
    const { defineCustomElements } =
      await import('@openhpi/xikolo-video-player/dist/components/index');

    const { initPreferenceAdapter } =
      await import('./preferences/preference-adapter');
    const { initTranscripts } = await import('./transcript');

    defineCustomElements();
    initPreferenceAdapter();
    initTranscripts();
  })();
  return videoPlayerLoaded;
};

turboReady(loadVideoPlayer);
