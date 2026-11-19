# frozen_string_literal: true

require 'spec_helper'

describe Video::Video, type: :model do
  subject(:video) { described_class.create!(params.merge(pip_stream_id: stream.id)) }

  let(:params) { attributes_for(:video) }
  let(:stream) { create(:stream) }

  describe '(deletion)' do
    before { video }
    around {|example| perform_enqueued_jobs(&example) }

    it 'deletes the video' do
      expect { video.destroy }.to change(Video::Video, :count).from(1).to(0)
    end

    context 'with attached reading material' do
      let(:params) { super().merge reading_material_uri: 's3://xikolo-public/reading_material.pdf' }

      let!(:delete_stub) do
        stub_request(
          :delete,
          "#{test_s3_host}/xikolo-public/reading_material.pdf"
        )
      end

      it 'deletes the referenced S3 object' do
        video.destroy
        expect(delete_stub).to have_been_requested
      end

      context 'with cloned video' do
        before do
          create(:video, reading_material_uri: video.reading_material_uri)
        end

        it 'does not remove the attached file' do
          video.destroy
          expect(delete_stub).not_to have_been_requested
        end
      end
    end

    context 'with an empty description' do
      let(:params) { attributes_for(:video).merge(description: nil) }

      it 'deletes the video' do
        expect { video.destroy }.to change(Video::Video, :count).from(1).to(0)
      end
    end
  end

  describe '(display streams)' do
    subject(:video) { create(:video, **streams) }

    let(:streams) { {pip_stream: create(:stream, :bunny)} }

    describe '#display_streams' do
      it 'lists the lecturer, slides and pip streams that are present' do
        expect(video.display_streams.map(&:id)).to eq([video.pip_stream.id])
      end

      context 'with a dual stream video' do
        let(:streams) do
          {pip_stream: nil, lecturer_stream: create(:stream, :bunny), slides_stream: create(:stream, :bunny)}
        end

        it 'lists both streams' do
          expect(video.display_streams.map(&:id)).to contain_exactly(video.lecturer_stream.id, video.slides_stream.id)
        end
      end

      it 'excludes the subtitled stream' do
        subtitled = create(:stream, :bunny)
        video.update!(subtitled_stream: subtitled)
        expect(video.display_streams).not_to include(subtitled)
      end
    end

    describe '#thumbnail' do
      context 'with a vimeo stream poster' do
        let(:streams) { {pip_stream: create(:stream, :vimeo)} }

        it 'returns the stored poster' do
          expect(video.thumbnail).to eq video.pip_stream.poster
        end
      end

      context 'with a bunny stream poster' do
        it 'returns the signed CDN thumbnail url' do
          guid = video.pip_stream.provider_video_id
          expect(video.thumbnail).to match(%r{#{guid}/thumbnail\.jpg\?token=[A-Za-z0-9_-]+&token_path=/#{guid}/&expires=\d+\z})
        end
      end

      context 'without any poster' do
        let(:streams) { {pip_stream: create(:stream, poster: nil)} }

        it 'returns nil' do
          expect(video.thumbnail).to be_nil
        end
      end

      context 'with multiple streams' do
        let(:streams) do
          {
            pip_stream: create(:stream, poster: nil),
            lecturer_stream: create(:stream, :bunny, provider_video_id: 'bunny-guid-9'),
            slides_stream: create(:stream, poster: nil),
          }
        end

        it 'falls back to the next stream that has a poster' do
          expect(video.thumbnail).to include('bunny-guid-9/thumbnail.jpg?token=')
        end
      end
    end

    describe '#bunny_stream' do
      it 'returns the single bunny stream' do
        expect(video.bunny_stream).to eq video.pip_stream
      end

      context 'with a vimeo stream' do
        let(:streams) { {pip_stream: create(:stream, :vimeo)} }

        it 'returns nil' do
          expect(video.bunny_stream).to be_nil
        end
      end

      context 'with a bunny stream without a provider video id' do
        let(:streams) { {pip_stream: create(:stream, :bunny, provider_video_id: nil)} }

        it 'returns nil' do
          expect(video.bunny_stream).to be_nil
        end
      end

      context 'with multiple bunny streams' do
        let(:streams) do
          {pip_stream: create(:stream, :bunny), lecturer_stream: create(:stream, :bunny)}
        end

        it 'returns the first display stream' do
          expect(video.bunny_stream).to eq video.lecturer_stream
        end
      end
    end
  end
end
