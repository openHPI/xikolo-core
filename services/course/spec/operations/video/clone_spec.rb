# frozen_string_literal: true

require 'spec_helper'

describe Video::Clone do
  subject(:new_video) do
    described_class.call(video)
  end

  let!(:video) { create(:'course_service/video') }

  it 'clones the video' do
    new_vid = nil
    expect { new_vid = new_video }.to change(Duplicated::Video, :count).from(1).to(2)
    expect(new_vid.pip_stream_id).to eq video.pip_stream_id
  end

  context 'with subtitles' do
    it 'copies the subtitles' do
      create(:'course_service/subtitle', video:)
      expect { new_video }.to change(Duplicated::Subtitle, :count).from(1).to(2)
    end

    context 'with subtitle cues' do
      it 'copies the related cues' do
        create(:'course_service/subtitle', :with_cues, video:)
        expect { new_video }.to change(Duplicated::SubtitleCue, :count).from(1).to(2)
      end
    end
  end

  context 'with file attachments' do
    # filename_v1.pdf
    context 'with old file versioning schema' do
      let(:video_id) { SecureRandom.uuid }

      context 'with slides attached' do
        let(:video) { create(:'course_service/video', :with_slides, id: video_id, slides_uri: "s3://xikolo-video/videos/#{video_id}/slides_v1.pdf") }
        let!(:copy_slides_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-Z0-9]+/slides_v1.pdf}
          ).and_return(
            status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="slides.pdf"'},
            body: '<xml></xml>'
          )
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video_id}/slides_v1.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="slides.pdf"'})
        end

        it 'clones the slides with its content disposition' do
          new_video
          expect(copy_slides_stub).to have_been_requested
          expect(new_video.slides_uri).to start_with('s3://xikolo-video/videos/')
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.slides_uri).not_to eq video.slides_uri
          expect(new_video.slides_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/slides_v1.pdf"
        end
      end

      context 'with a transcript attached' do
        let(:video) { create(:'course_service/video', :with_transcript, id: video_id, transcript_uri: "s3://xikolo-video/videos/#{video_id}/transcript_v1.pdf") }
        let!(:copy_transcript_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-Z0-9]+/transcript_v1.pdf}
          ).and_return(
            status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="transcript.pdf"'},
            body: '<xml></xml>'
          )
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video_id}/transcript_v1.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="transcript.pdf"'})
        end

        it 'clones the transcript with its content disposition' do
          new_video
          expect(copy_transcript_stub).to have_been_requested
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.transcript_uri).not_to eq video.transcript_uri
          expect(new_video.transcript_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/transcript_v1.pdf"
        end
      end

      context 'with reading material attached' do
        let(:video) { create(:'course_service/video', :with_reading_material, id: video_id, reading_material_uri: "s3://xikolo-video/videos/#{video_id}/reading_material_v1.pdf") }
        let!(:copy_reading_material_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-Z0-9]+/reading_material_v1.pdf}
          ).and_return(
            status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="reading_material.pdf"'},
            body: '<xml></xml>'
          )
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video.id}/reading_material_v1.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="reading_material.pdf"'})
        end

        it 'clones the reading material with its content disposition' do
          new_video
          expect(copy_reading_material_stub).to have_been_requested
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.reading_material_uri).not_to eq video.reading_material_uri
          expect(new_video.reading_material_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/reading_material_v1.pdf"
        end
      end
    end

    # unique_sanitized_name(filename).pdf --> uuid/filename.pdf
    context 'with new file versioning schema' do
      context 'with slides attached' do
        let!(:video) { create(:'course_service/video', :with_slides) }
        let!(:copy_slides_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-z0-9]+/encodedUUUID/slides.pdf}
          ).and_return(status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="slides.pdf"'},
            body: '<xml></xml>')
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video.id}/encodedUUUID/slides.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="slides.pdf"'})
        end

        it 'clones the slides with its content disposition' do
          new_video
          expect(copy_slides_stub).to have_been_requested
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.slides_uri).not_to eq video.slides_uri
          expect(new_video.slides_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/encodedUUUID/slides.pdf"
        end
      end

      context 'with a transcript attached' do
        let(:video) { create(:'course_service/video', :with_transcript) }
        let!(:copy_transcript_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-Z0-9]+/encodedUUUID/transcript.pdf}
          ).and_return(status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="transcript.pdf"'},
            body: '<xml></xml>')
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video.id}/encodedUUUID/transcript.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="transcript.pdf"'})
        end

        it 'clones the transcript with its content disposition' do
          new_video
          expect(copy_transcript_stub).to have_been_requested
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.transcript_uri).not_to eq video.transcript_uri
          expect(new_video.transcript_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/encodedUUUID/transcript.pdf"
        end
      end

      context 'with reading material attached' do
        let(:video) { create(:'course_service/video', :with_reading_material) }
        let!(:copy_reading_material_stub) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-video/videos/[a-zA-Z0-9]+/encodedUUUID/reading_material.pdf}
          ).and_return(status: 200,
            headers: {'Content-Disposition' => 'attachment; filename="reading_material.pdf"'},
            body: '<xml></xml>')
        end

        before do
          stub_request(:head, "https://s3.xikolo.de/xikolo-video/videos/#{video.id}/encodedUUUID/reading_material.pdf")
            .to_return(status: 200, headers: {'Content-Disposition' => 'attachment; filename="reading_material.pdf"'})
        end

        it 'clones the reading material with its content disposition' do
          new_video
          expect(copy_reading_material_stub).to have_been_requested
        end

        it 'updates the associated file' do
          new_video
          expect(new_video.reading_material_uri).not_to eq video.reading_material_uri
          expect(new_video.reading_material_uri).to eq "s3://xikolo-video/videos/#{UUID4(new_video.id).to_s(format: :base62)}/encodedUUUID/reading_material.pdf"
        end
      end
    end
  end
end
