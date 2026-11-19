# frozen_string_literal: true

require 'spec_helper'

describe Course::Visual::Store, type: :operation do
  subject(:operation) { described_class.call(visual, params) }

  let!(:visual) { build(:visual, image_uri: nil) }
  let(:params) { {image_upload_id: upload_id} }
  let(:upload_id) { generate(:uuid) }
  let(:file_url) { "#{test_s3_host}/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
  let(:image_url) { %r{#{test_s3_host}/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }
  let(:stream) { create(:stream) }
  let(:file_name) { 'image.png' }

  # S3-related stubs
  let(:list_stub) do
    stub_request(:get, "#{test_s3_host}/xikolo-uploads?list-type=2&prefix=uploads%2F#{upload_id}")
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/#{upload_id}</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/#{upload_id}/#{file_name}</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
  end
  let(:successful_read_stub) do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_course_image',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:rejected_read_stub) do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_course_image',
        'X-Amz-Meta-Xikolo-State' => 'rejected',
      }
    )
  end
  let(:forbidden_read_stub) do
    stub_request(:head, file_url).to_return(status: 403)
  end
  let(:successful_store_stub) do
    stub_request(:put, image_url).to_return(status: 200, body: '<xml></xml>')
  end
  let(:forbidden_store_stub) do
    stub_request(:put, image_url).to_return(status: 403)
  end

  context 'when uploading a teaser video' do
    let(:video_file) do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/support/files/video-sd.mp4'), 'video/mp4')
    end
    let(:params) { {teaser_video: video_file} }

    it 'attaches a pending Bunny stream using the existing video models' do
      operation

      stream = visual.reload.video_stream
      expect(stream.provider.provider_type).to eq 'bunny'
      expect(stream.title).to eq "#{visual.course.course_code}_teaser"
      expect(stream.video).to be_attached
      expect(stream.provider_video_id).to be_nil
      expect(stream).to be_waiting
    end

    it 'queues the existing Bunny upload job after saving the teaser' do
      expect { operation }.to have_enqueued_job(UploadStreamToBunnyJob)
      expect(enqueued_jobs.find {|job| job[:job] == UploadStreamToBunnyJob }[:args]).to eq [visual.reload.video_stream.id]
    end

    context 'with an existing teaser' do
      let!(:old_video) { create(:video, :with_subtitles) }

      before { visual.update!(video: old_video) }

      it 'replaces the stream and removes the previous subtitles' do
        operation

        expect(visual.reload.video.id).to eq old_video.id
        expect(visual.video_stream.provider.provider_type).to eq 'bunny'
        expect(visual.video.subtitles).to be_empty
      end
    end

    context 'when keeping the current stream without uploading another file' do
      let!(:old_video) { create(:video) }
      let(:params) { {video_stream_id: old_video.pip_stream_id, teaser_video: ''} }

      before { visual.update!(video: old_video) }

      it 'preserves the current teaser without another upload' do
        expect { operation }.not_to have_enqueued_job(UploadStreamToBunnyJob)
        expect(visual.reload.video_stream.id).to eq old_video.pip_stream_id
      end
    end

    context 'with a directly uploaded blob' do
      let(:video_file) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('video data'), filename: 'teaser.mp4', content_type: 'video/mp4'
        ).signed_id
      end

      it 'attaches the uploaded file' do
        operation

        expect(visual.reload.video_stream.video.filename.to_s).to eq 'teaser.mp4'
      end
    end

    context 'with an invalid blob reference' do
      let(:video_file) { 'invalid-signed-id' }

      it 'rolls back the upload without queuing a job' do
        expect { operation }.not_to change(Video::Stream, :count)
        expect(enqueued_jobs.none? {|job| job[:job] == UploadStreamToBunnyJob }).to be true
        expect(visual).not_to be_persisted
      end
    end
  end

  context 'without existing course visual' do
    context 'when uploading a course image' do
      let(:params) { {image_upload_id: upload_id} }

      before { list_stub }

      context 'with successful image upload' do
        before do
          successful_read_stub
          successful_store_stub
        end

        it 'creates a new course visual with image' do
          expect { operation }.to change(Course::Visual, :count).from(0).to(1)
          expect(successful_store_stub).to have_been_requested
          expect(visual.reload.image_url).to match image_url
          expect(visual.reload.video).to be_nil
        end
      end

      context 'with rejected image upload' do
        before { rejected_read_stub }

        it 'does not create a course visual' do
          expect { operation }.not_to change(Course::Visual, :count).from(0)
        end
      end

      context 'without access permission' do
        before { forbidden_read_stub }

        it 'does not create a course visual' do
          expect { operation }.not_to change(Course::Visual, :count).from(0)
        end
      end

      context 'when saving to destination is forbidden' do
        before do
          successful_read_stub
          forbidden_store_stub
        end

        it 'does not create a course visual' do
          expect { operation }.not_to change(Course::Visual, :count).from(0)
        end
      end
    end

    context 'when selecting a course teaser video' do
      let(:params) { {video_stream_id: stream.id} }

      it 'creates a new course visual with teaser video' do
        expect { operation }.to change(Course::Visual, :count).from(0).to(1)
          .and change(Video::Video, :count).from(0).to(1)
        expect(visual.reload.image_url).to be_nil
        expect(visual.reload.video).to be_a Video::Video
        expect(visual.reload.video_stream.id).to eq params[:video_stream_id]
      end
    end

    context 'when setting both a course image and teaser video' do
      let(:params) do
        {
          image_upload_id: upload_id,
          video_stream_id: stream.id,
        }
      end

      before { list_stub }

      context 'with successful image upload' do
        before do
          successful_read_stub
          successful_store_stub
        end

        it 'creates a new course visual' do
          expect { operation }.to change(Course::Visual, :count).from(0).to(1)
        end

        it 'uploads the course image' do
          operation
          expect(successful_store_stub).to have_been_requested
          expect(visual.reload.image_url).to match image_url
        end

        it 'creates a new teaser video' do
          expect { operation }.to change(Video::Video, :count).from(0).to(1)
          expect(visual.reload.video).to be_a Video::Video
          expect(visual.reload.video_stream.id).to eq params[:video_stream_id]
        end
      end

      context 'with failing image upload' do
        before { rejected_read_stub }

        it 'does not create a course visual' do
          expect { operation }.not_to change(Course::Visual, :count).from(0)
        end
      end
    end
  end

  context 'with existing course visual' do
    let!(:visual) { create(:visual, :with_video, image_uri: old_image_uri) }
    let(:old_image_uri) { 's3://xikolo-public/courses/1/42/old_image.png' }

    context 'when replacing the course image' do
      let(:params) { {image_upload_id: upload_id, video_stream_id: visual.video_stream.id} }

      before { list_stub }

      context 'with successful image upload' do
        before do
          successful_read_stub
          successful_store_stub
        end

        it 'updates the existing course visual' do
          expect { operation }.not_to change(Course::Visual, :count).from(1)
        end

        it 'updates the course image' do
          expect { operation }.to change { visual.reload.image_url }
            .from("#{test_s3_host}/xikolo-public/courses/1/42/old_image.png")
            .to(image_url)
          expect(successful_store_stub).to have_been_requested
        end

        it 'schedules the removal of the old course image' do
          expect { operation }.to have_enqueued_job(S3FileDeletionJob).with(old_image_uri)
        end

        it 'does not change the course teaser video' do
          expect { operation }.not_to change { visual.reload.video_stream.id }
        end
      end

      context 'with rejected image upload' do
        before { rejected_read_stub }

        it 'does not change the course visual' do
          expect { operation }.not_to change(visual, :reload)
        end

        it 'does not schedule the removal of the old course image' do
          expect { operation }.not_to have_enqueued_job(S3FileDeletionJob)
        end
      end

      context 'without access permission' do
        before { forbidden_read_stub }

        it 'does not change the course visual' do
          expect { operation }.not_to change(visual, :reload)
        end

        it 'does not schedule the removal of the old course image' do
          expect { operation }.not_to have_enqueued_job(S3FileDeletionJob)
        end
      end

      context 'when saving to destination is forbidden' do
        before do
          successful_read_stub
          forbidden_store_stub
        end

        it 'does not change the course visual' do
          expect { operation }.not_to change(visual, :reload)
        end

        it 'does not schedule the removal of the old course image' do
          expect { operation }.not_to have_enqueued_job(S3FileDeletionJob)
        end
      end
    end

    context 'when the course image is removed' do
      let(:params) { {image_uri: nil, video_stream_id: visual.video_stream.id} }

      it 'removes the course image' do
        expect { operation }.to change { visual.reload.image_url }
          .from("#{test_s3_host}/xikolo-public/courses/1/42/old_image.png")
          .to(nil)
        expect(visual.reload.image_uri).to be_nil
      end

      it 'schedules the removal of the old course image' do
        expect { operation }.to have_enqueued_job(S3FileDeletionJob).with(old_image_uri)
      end

      it 'does not change the course teaser video' do
        expect { operation }.not_to change { visual.reload.video_stream.id }
      end
    end

    context 'when the course teaser video is removed' do
      let(:params) { {video_stream_id: nil} }

      it 'removes the course teaser video' do
        expect { operation }.to change { visual.reload.video_stream }.to(nil)
      end

      it 'does not schedule the removal of the old course image' do
        expect { operation }.not_to have_enqueued_job(S3FileDeletionJob)
      end

      it 'does not change the course image' do
        expect { operation }.not_to change { visual.reload.image_url }
      end

      it 'destroys the video' do
        expect { operation }.to change(Video::Video, :count).from(1).to(0)
      end

      context 'when subtitles have been uploaded' do
        before do
          create(:video_subtitle, :with_cues, cues: 2, video: visual.video)
        end

        it 'deletes existing subtitles' do
          expect { operation }.to change(Video::Subtitle, :count).from(1).to(0)
            .and change(Video::SubtitleCue, :count).from(2).to(0)
        end
      end
    end

    context 'when the course teaser video is updated' do
      let(:other_stream) { create(:stream) }
      let(:params) { {video_stream_id: other_stream.id} }

      it 'updates the course teaser video' do
        expect { operation }.to change { visual.reload.video_stream.id }.to params[:video_stream_id]
      end

      it 'does not change the course image' do
        expect { operation }.not_to change { visual.reload.image_url }
      end

      it 'does not schedule the removal of the course image' do
        expect { operation }.not_to have_enqueued_job(S3FileDeletionJob)
      end

      context 'when subtitles have been uploaded for the old teaser video' do
        before do
          create(:video_subtitle, :with_cues, cues: 2, video: visual.video)
        end

        it 'deletes existing subtitles' do
          expect { operation }.to change(Video::Subtitle, :count).from(1).to(0)
            .and change(Video::SubtitleCue, :count).from(2).to(0)
        end
      end
    end
  end

  context '(subtitles upload)' do
    let!(:visual) { create(:visual, :with_video, image_uri: nil) }
    let(:subtitles_upload_id) { generate(:uuid) }
    let(:subtitles_file_url) { "#{test_s3_host}/xikolo-uploads/uploads/#{subtitles_upload_id}/video-subtitles.zip" }

    let(:list_stub) do
      stub_request(:get, "#{test_s3_host}/xikolo-uploads?list-type=2&prefix=uploads%2F#{subtitles_upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{subtitles_upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{subtitles_upload_id}/video-subtitles.zip</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
    end
    let(:read_stub) do
      stub_request(:head, subtitles_file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'video_subtitles',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
    end

    before do
      list_stub
      read_stub
      stub_request(:get, subtitles_file_url).to_return(
        body: File.new(Rails.root.join('spec/support/files/video/subtitles/video-subtitles.zip')),
        status: 200
      )
    end

    context 'with selected teaser video' do
      let(:params) { {subtitles_upload_id:, video_stream_id: stream.id} }

      it 'processes the subtitles' do
        operation
        expect(visual.video.reload.subtitles).not_to be_empty
        expect(visual.video.reload.subtitles.pluck(:lang)).to contain_exactly('de', 'en')
      end
    end

    context 'without selected teaser video' do
      let(:params) { {subtitles_upload_id:, video_stream_id: ''} }

      it 'does not process the subtitles' do
        operation
        expect(visual.video.reload.subtitles).to be_empty
      end
    end
  end
end
