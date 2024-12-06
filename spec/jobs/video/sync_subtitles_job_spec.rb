# frozen_string_literal: true

require 'spec_helper'

describe Video::SyncSubtitlesJob, type: :job do
  describe '#perform' do
    subject(:perform) { described_class.perform_later(video.id, 'de') }

    let!(:video) { create(:video, pip_stream: stream) }
    let!(:stream) { create(:stream) }
    let(:adapter) { instance_double(Video::VimeoAdapter, remove_subtitles!: true, attach_subtitles!: true) }

    before { allow(Video::VimeoAdapter).to receive(:new).and_return(adapter) }

    around {|example| perform_enqueued_jobs(&example) }

    context 'when there are no subtitles for the given language' do
      let(:subtitle_de) { nil }

      before do
        create(:video_subtitle, :with_cues, video:, lang: 'de')
      end

      it "removes the existing subtitles for the video's PIP stream" do
        perform
        expect(adapter).to have_received(:remove_subtitles!).with(stream, 'de').once
        expect(adapter).not_to have_received(:attach_subtitles!).with(stream, subtitle_de)
      end
    end

    context 'with subtitles for the given language' do
      let!(:subtitle_de) { create(:video_subtitle, :with_cues, video:, lang: 'de') }

      before do
        create(:video_subtitle, :with_cues, lang: 'en')
      end

      it "removes the existing subtitles and attaches the new subtitle to the video's PIP stream" do
        perform
        expect(adapter).to have_received(:remove_subtitles!).with(stream, 'de').once
        expect(adapter).to have_received(:attach_subtitles!).with(stream, subtitle_de).once
      end

      context 'without a pip stream' do
        let(:video) { create(:video, pip_stream: nil, lecturer_stream: stream) }

        it "removes the existing subtitles and attaches the new subtitle to the video's lecturer stream" do
          perform
          expect(adapter).to have_received(:remove_subtitles!).with(stream, 'de').once
          expect(adapter).to have_received(:attach_subtitles!).with(stream, subtitle_de).once
        end
      end

      context 'without a pip and a lecturer stream' do
        let(:video) { create(:video, pip_stream: nil, lecturer_stream: nil, slides_stream: stream) }

        it "removes the existing subtitles and attaches the new subtitle to the video's slides stream" do
          perform
          expect(adapter).to have_received(:remove_subtitles!).with(stream, 'de').once
          expect(adapter).to have_received(:attach_subtitles!).with(stream, subtitle_de).once
        end
      end
    end
  end
end
