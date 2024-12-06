# frozen_string_literal: true

require 'spec_helper'

describe Video::Stream, type: :model do
  subject(:the_stream) { create(:stream, params) }

  let(:params) { {} }

  describe '(validations)' do
    it { is_expected.not_to accept_values_for(:title, '') }
    it { is_expected.not_to accept_values_for(:provider, nil) }
    it { is_expected.not_to accept_values_for(:provider_video_id, '', nil) }

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
