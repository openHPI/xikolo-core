/**
 * When selecting a PIP stream, let's try to automatically find matching
 * lecturer and slides streams.
 */

import { TomInput } from 'tom-select/dist/types/types';

const streamMatching = (regex: RegExp) => (stream: { text: string }) =>
  stream.text.match(regex);

const fetchAndAddData = async (commonBase: string) => {
  try {
    const response = await fetch(
      `/admin/streams?q=${encodeURIComponent(commonBase)}`,
    );
    const data = await response.json();
    const lecturer = data.find(streamMatching(/-lecturer(\.mp4)?\s\(.+\)$/));
    const slides = data.find(
      streamMatching(/-(slides|desktop)(\.mp4)?\s\(.+\)$/),
    );

    if (lecturer) {
      const select = document.querySelector<TomInput>(
        '#video_lecturer_stream_id',
      )?.tomselect;
      select?.addOption({ id: lecturer.id, text: lecturer.text });
      select?.addItem(lecturer.id);
    }

    if (slides) {
      const select = document.querySelector<TomInput>(
        '#video_slides_stream_id',
      )?.tomselect;
      select?.addOption({ id: slides.id, text: slides.text });
      select?.addItem(slides.id);
    }
  } catch (error) {
    console.error('Error fetching streams data:', error);
  }
};

const videoStreamsAutocompletion = () => {
  const pipStreamSelector = document.querySelector<HTMLSelectElement>(
    '#video_pip_stream_id',
  );
  pipStreamSelector?.addEventListener('change', (e) => {
    const target = e.target as HTMLSelectElement;
    if (target.selectedIndex === -1) return;

    const pipStream = target.selectedOptions[0].label;
    if (!pipStream.match(/-pip(\.mp4)?\s\(.+\)$/)) return;

    // Remove (optional) file extension and "-pip" suffix
    const commonBase = pipStream.substring(0, pipStream.lastIndexOf('-pip'));

    fetchAndAddData(commonBase);
  });
};

export default videoStreamsAutocompletion;
