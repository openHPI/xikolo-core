# frozen_string_literal: true

require 'spec_helper'

describe Video::Stream, type: :model do
  subject(:the_stream) { create(:stream, params) }

  let(:params) { {} }

  describe '(validations)' do
    it { is_expected.not_to accept_values_for(:title, '') }
    it { is_expected.not_to accept_values_for(:provider, nil) }

    # A stream may be persisted before it is backed by the provider
    # (no provider video id / urls yet, e.g. a freshly uploaded Bunny video).
    context 'for a pending stream (no provider video id)' do
      let(:params) { super().merge(provider_video_id: nil, hd_url: '', sd_url: '', hls_url: nil) }

      it { is_expected.to be_valid }
    end

    describe 'multiple streams' do
      context 'with same provider_video_id' do
        let(:provider_video_id) { '196305407' }
        let(:params) { super().merge(provider_video_id:) }
        let!(:existing_stream) { create(:stream, provider_video_id:) }

        context 'for same provider' do
          let(:params) { super().merge(provider_id: existing_stream.provider_id) }

          it 'raises an error' do
            expect { the_stream }.to raise_error(ActiveRecord::RecordInvalid) do |error|
              expect(error.record.errors.messages).to eq(provider_video_id: ['has already been taken'])
            end
          end
        end

        context 'for different provider' do
          it { is_expected.to be_valid }
        end
      end
    end

    describe 'download URLs' do
      context 'with one download URL missing' do
        context 'without HD' do
          let(:params) { super().merge! hd_url: '' }

          it { is_expected.to be_valid }
        end

        context 'without SD' do
          let(:params) { super().merge! sd_url: '' }

          it { is_expected.to be_valid }
        end
      end

      context 'with both download URLs missing' do
        let(:params) { super().merge! sd_url: '', hd_url: '' }

        it 'requires at least one URL' do
          expect { the_stream }.to raise_error(ActiveRecord::RecordInvalid) do |error|
            expect(error.record.errors.to_hash).to eq(
              sd_url: ['At least one URL is required.'],
              hd_url: ['At least one URL is required.']
            )
          end
        end

        context 'but with an HLS URL' do
          let(:params) { super().merge! hls_url: 'https://cdn.example.com/stream.m3u8' }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '#start_upload!' do
    context 'for a bunny stream' do
      it 'marks the stream as waiting' do
        stream = create(:stream, :bunny)
        expect { stream.start_upload! }
          .to change { stream.reload.upload_state }.from('ready').to('waiting')
      end
    end

    context 'for a vimeo stream' do
      it 'keeps the stream ready' do
        stream = create(:stream)
        stream.start_upload!
        expect(stream.reload.upload_state).to eq 'ready'
      end
    end
  end

  describe '#mark_uploading!' do
    subject(:the_stream) { create(:stream, :bunny, :with_video, upload_state: 'waiting') }

    it 'marks the stream as uploading' do
      expect { the_stream.mark_uploading! }.to change { the_stream.reload.upload_state }.from('waiting').to('uploading')
    end
  end

  describe '#mark_upload_ready!' do
    subject(:the_stream) { create(:stream, :bunny, :with_video, upload_state: 'uploading', upload_error: 'boom') }

    it 'marks the stream as ready and clears the error' do
      expect { the_stream.mark_upload_ready! }
        .to change { the_stream.reload.upload_state }.from('uploading').to('ready')
      expect(the_stream.reload.upload_error).to be_nil
    end
  end

  describe '#mark_upload_failed!' do
    subject(:the_stream) { create(:stream, :bunny, :with_video, upload_state: 'uploading') }

    it 'marks the stream as failed and records the error' do
      expect { the_stream.mark_upload_failed!(StandardError.new('Bunny is down')) }
        .to change { the_stream.reload.upload_state }.from('uploading').to('failed')
      expect(the_stream.reload.upload_error).to eq 'Bunny is down'
    end
  end

  describe '#retry_upload!' do
    let(:stream) { create(:stream, :bunny, :with_video, upload_state: 'failed', upload_error: 'Bunny is down') }

    it 'resets the stream to waiting and enqueues the upload job' do
      expect { stream.retry_upload! }
        .to change { stream.reload.upload_state }.from('failed').to('waiting')
        .and have_enqueued_job(UploadStreamToBunnyJob).with(stream.id)
      expect(stream.reload.upload_error).to be_nil
    end

    context 'when the stream is not failed' do
      let(:stream) { create(:stream, :bunny, :with_video, upload_state: 'ready') }

      it 'raises an error' do
        expect { stream.retry_upload! }.to raise_error(RuntimeError, /Only failed uploads can be retried/)
      end
    end
  end

  describe '#poster_url' do
    context 'for a bunny stream' do
      let(:stream) { create(:stream, :bunny, provider_video_id: 'bunny-guid-1') }

      it 'returns the signed CDN thumbnail url' do
        expect(stream.poster_url).to match(%r{bunny-guid-1/thumbnail\.jpg\?token=[A-Za-z0-9_-]+&token_path=/bunny-guid-1/&expires=\d+\z})
      end
    end

    context 'for a vimeo stream' do
      let(:stream) { create(:stream) }

      it 'returns the stored poster as-is' do
        expect(stream.poster_url).to eq stream.poster
      end
    end

    context 'for a pending bunny stream without a provider video id' do
      let(:stream) do
        create(:stream, :bunny, provider_video_id: nil, hls_url: 'https://cdn.example.com/x/playlist.m3u8')
      end

      it 'returns the stored poster as-is' do
        expect(stream.poster_url).to eq stream.poster
      end
    end

    context 'without a poster' do
      let(:stream) { create(:stream, :bunny, provider_video_id: 'bunny-guid-2', poster: nil) }

      it 'returns nil' do
        expect(stream.poster_url).to be_nil
      end
    end
  end

  describe '#upload_status' do
    it 'returns :none for provider-synced streams' do
      stream = build(:stream)
      expect(stream.upload_status).to eq :none
    end

    it 'returns :ready for a ready Bunny stream' do
      stream = build(:stream, :bunny, provider_video_id: 'guid-1', hls_url: 'https://cdn.example.com/guid-1/playlist.m3u8')
      expect(stream.upload_status).to eq :ready
    end

    it 'returns :waiting for a waiting Bunny stream' do
      stream = build(:stream, :bunny, provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil, upload_state: 'waiting')
      expect(stream.upload_status).to eq :waiting
    end

    it 'returns :uploading for an uploading Bunny stream' do
      stream = build(:stream, :bunny, provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil, upload_state: 'uploading')
      expect(stream.upload_status).to eq :uploading
    end

    it 'returns :invalid for a failed Bunny stream without a provider video' do
      stream = build(:stream, :bunny, provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil, upload_state: 'failed')
      expect(stream.upload_status).to eq :invalid
    end

    it 'returns :failed for a failed Bunny stream with a provider video' do
      stream = build(:stream, :bunny, provider_video_id: 'guid-1', hls_url: 'https://cdn.example.com/guid-1/playlist.m3u8', upload_state: 'failed')
      expect(stream.upload_status).to eq :failed
    end
  end

  describe '(audio extraction)' do
    subject(:the_stream) { build(:stream, params) }

    let(:params) do
      super().merge!(
        sd_md5: 'e6131c05d0e91a7c6d9483e133ad58e8',
        audio_uri: 's3://xikolo-video/streams/3uAdfU6wveIxOGrQ7qa7mp/audio_v1.mp3'
      )
    end

    before do
      xi_config <<~YML
        video:
          audio_extraction: true
      YML
    end

    it 'triggers the audio extraction' do
      expect { the_stream.save! }.to have_enqueued_job(Video::ExtractAudioJob).with(the_stream.id)
    end
  end

  describe '.query' do
    subject(:query_filter) { described_class.query(term) }

    before do
      create(:stream, title: 'old-stream', created_at: 1.week.ago)
      create(:stream, title: 'new-stream-1', created_at: 2.days.ago)
      create(:stream, title: 'new-stream-2', created_at: 1.day.ago)
      create(:stream, title: 'Stream-3', created_at: 2.hours.ago)
    end

    context 'when not filtering videos' do
      let(:term) { nil }

      it 'returns all streams by creation date (default order)' do
        expect(query_filter).to match([
          an_object_having_attributes(title: 'Stream-3'),
          an_object_having_attributes(title: 'new-stream-2'),
          an_object_having_attributes(title: 'new-stream-1'),
          an_object_having_attributes(title: 'old-stream'),
        ])
      end
    end

    context 'when filtering by a term that matches any part of the title' do
      let(:term) { 'stre' }

      before do
        create(:stream, title: 'Another one')
      end

      it 'returns matching streams sorted alphabetically' do
        expect(query_filter).to match([
          an_object_having_attributes(title: 'new-stream-1'),
          an_object_having_attributes(title: 'new-stream-2'),
          an_object_having_attributes(title: 'old-stream'),
          an_object_having_attributes(title: 'Stream-3'), # Case-insensitive match
        ])
      end
    end

    context 'when filtering by a term that matches the prefix of the title' do
      let(:term) { 'new' }

      it 'returns matching streams sorted alphabetically' do
        expect(query_filter).to match([
          an_object_having_attributes(title: 'new-stream-1'),
          an_object_having_attributes(title: 'new-stream-2'),
        ])
      end
    end
  end
end
