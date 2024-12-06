# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Video::Store do
  subject(:store_video) { described_class.call(video, update_params) }

  let(:video_id) { SecureRandom.uuid }
  let(:initial_params) { {id: video_id} }
  let(:video) { create(:video, initial_params) }
  let(:update_params) { {} }

  # Stub request setup
  let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }

  let(:store_stub) do
    stub_request(:put, store_stub_url).to_return(
      status: 200,
      headers: {'Content-Type' => 'application/xml'},
      body: <<~XML)
        <CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <LastModified>2018-08-02T15:42:36.430Z</LastModified>
          <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
        </CopyObjectResult>
      XML
  end
  let(:upload_stub) do
    stub_request(:get,
      'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
      "prefix=uploads%2F#{upload_id}") \
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
  let(:upload_check_stub) do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => purpose,
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:store_check_stub) do
    stub_request(:head, store_stub_url).to_return(status: 404)
  end

  shared_examples 'does not update the attachment' do |attachment|
    it 'handles the error gracefully' do
      expect { store_video }.not_to raise_error
    end

    it 'does not update the video' do
      store_video
      expect(Video::Video.first).to eq video
    end

    it 'adds the error to the attribute' do
      store_video
      expect(video.errors.errors.first.attribute).to eq attachment
      expect(video.errors.errors.first.type).to eq :upload_error
    end
  end

  shared_examples 'backward-compatible S3-upload' do
    it 'stores the attatchment file in S3' do
      store_video
      expect(store_stub).to have_been_requested
    end
  end

  describe '(updating reading_material_uri)' do
    let(:reading_material_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/encodedUUUID/reading_material.pdf" }
    let(:initial_params) { super().merge reading_material_uri: }

    context 'with newly uploaded reading material' do
      let(:upload_id) { SecureRandom.uuid }
      let(:update_params) { super().merge reading_material_upload_id: upload_id }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          "uploads/#{upload_id}/new_reading_material.pdf"
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          "prefix=uploads%2F#{upload_id}") \
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
                  <Key>uploads/#{upload_id}/new_reading_material.pdf</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
      end

      context 'with a valid reading material file upload' do
        let!(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'application/xml'},
              body: <<~XML)
                <CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_material',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it 'stores the reading material file in S3' do
          store_video
          expect(store_stub).to have_been_requested
        end

        it 'updates the reading_material_uri on the video' do
          store_video
          expect(video.reload.reading_material_uri).not_to eq reading_material_uri
          expect(video.reload.reading_material_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_reading_material.pdf})
        end

        it 'deletes the old file' do
          expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(reading_material_uri)
        end
      end

      context 'with an invalid reading material file upload' do
        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_material',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          include_examples 'does not update the attachment', :reading_material_uri
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          include_examples 'does not update the attachment', :reading_material_uri
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_material',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf})
              .to_return(status: 403)
          end

          include_examples 'does not update the attachment', :reading_material_uri
        end
      end

      context 'with copied video references the same S3 reference' do
        let(:reading_material_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/encodedUUUID/reading_material.pdf" }
        let!(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'applhttp:ication/xml', 'Content-Disposition' => 'attachment; filename="new_reading_material.pdf"'},
              body: <<~XML)
                <CopyObjectResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          # Create another video with the same file reference
          create(:video, reading_material_uri: video.reading_material_uri)

          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_material',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it 'stores the reading material file in S3' do
          store_video
          expect(store_stub).to have_been_requested
        end

        it 'updates the reading_material_uri on the video' do
          store_video
          expect(video.reload.reading_material_uri).not_to eq reading_material_uri
          expect(video.reload.reading_material_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_reading_material.pdf})
        end

        it 'does not delete the old file' do
          expect { store_video }.not_to have_enqueued_job(S3FileDeletionJob).with(reading_material_uri)
        end
      end
    end

    context 'with a request to delete the reading material' do
      let(:update_params) { {reading_material_url: nil} }

      it 'clears the reading_material_uri on the video' do
        expect { store_video }.to change { video.reload.reading_material_uri }.from(reading_material_uri).to(nil)
      end

      it 'deletes the old file' do
        expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(reading_material_uri)
      end
    end

    context 'with a backward-compatible S3-upload' do
      let(:upload_id) { SecureRandom.uuid }
      let(:file_name) { 'new_reading_material.pdf' }
      let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf} }
      let(:purpose) { 'video_material' }

      before do
        store_stub
        upload_stub
        upload_check_stub
        store_check_stub
      end

      context 'via id' do
        let(:update_params) { super().merge reading_material_upload_id: upload_id }

        include_examples 'backward-compatible S3-upload'
      end

      context 'via uri' do
        let(:new_uri) { "upload://#{upload_id}/#{file_name}" }
        let(:update_params) { super().merge reading_material_uri: new_uri }

        include_examples 'backward-compatible S3-upload'
      end
    end
  end

  describe '(updating slides_uri)' do
    let(:slides_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/#{UUID4.new.to_s(format: :base62)}/slides.pdf" }
    let(:initial_params) { super().merge slides_uri: }

    context 'with newly uploaded slides' do
      let(:upload_id) { SecureRandom.uuid }
      let(:update_params) { super().merge slides_upload_id: upload_id }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          "uploads/#{upload_id}/new_slides.pdf"
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          "prefix=uploads%2F#{upload_id}") \
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
                  <Key>uploads/#{upload_id}/new_slides.pdf</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
      end

      context 'with a valid slides file upload' do
        let!(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_slides.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'application/xml'},
              body: <<~XML)
                <CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_slides',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it 'stores the slides file in S3' do
          store_video
          expect(store_stub).to have_been_requested
        end

        it 'updates the slides_uri on the video' do
          store_video
          expect(video.reload.slides_uri).not_to eq slides_uri
          expect(video.reload.slides_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_slides.pdf})
        end

        it 'deletes the old file' do
          expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(slides_uri)
        end
      end

      context 'with an invalid slides file upload' do
        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_slides',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          include_examples 'does not update the attachment', :slides_uri
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          include_examples 'does not update the attachment', :slides_uri
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_slides',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_slides.pdf})
              .to_return(status: 403)
          end

          include_examples 'does not update the attachment', :slides_uri
        end
      end

      context 'with copied video references the same S3 reference' do
        let(:slides_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/encodedUUUID/slides.pdf" }
        let!(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_slides.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'applhttp:ication/xml', 'Content-Disposition' => 'attachment; filename="new_slides.pdf"'},
              body: <<~XML)
                <CopyObjectResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          # Create another video with the same file reference
          create(:video, slides_uri: video.slides_uri)

          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_slides',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it 'stores the slides file in S3' do
          store_video
          expect(store_stub).to have_been_requested
        end

        it 'updates the slides_uri on the video' do
          store_video
          expect(video.reload.slides_uri).not_to eq slides_uri
          expect(video.reload.slides_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_slides.pdf})
        end

        it 'does not delete the old file' do
          expect { store_video }.not_to have_enqueued_job(S3FileDeletionJob).with(slides_uri)
        end
      end
    end

    context 'with a request to delete the slides' do
      let(:update_params) { {slides_url: nil} }

      it 'clears the slides_uri on the video' do
        expect { store_video }.to change { video.reload.slides_uri }.from(slides_uri).to(nil)
      end

      it 'deletes the old file' do
        expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(slides_uri)
      end
    end

    context 'with a backward-compatible S3-upload' do
      let(:upload_id) { SecureRandom.uuid }
      let(:file_name) { 'new_slides.pdf' }
      let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
      let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_slides.pdf} }
      let(:purpose) { 'video_slides' }

      before do
        store_stub
        store_check_stub
        upload_stub
        upload_check_stub
      end

      context 'via ID' do
        let(:update_params) { super().merge slides_upload_id: upload_id }

        include_examples 'backward-compatible S3-upload'
      end

      context 'via URI' do
        let(:new_uri) { "upload://#{upload_id}/#{file_name}" }
        let(:update_params) { super().merge slides_uri: new_uri }

        include_examples 'backward-compatible S3-upload'
      end
    end
  end

  describe '(updating transcript_uri)' do
    let(:transcript_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/encodedUUUID/transcript.pdf" }
    let(:initial_params) { super().merge transcript_uri: }

    context 'with newly uploaded transcript' do
      let(:upload_id) { SecureRandom.uuid }
      let(:update_params) { super().merge transcript_upload_id: upload_id }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          "uploads/#{upload_id}/new_transcript.pdf"
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          "prefix=uploads%2F#{upload_id}") \
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
                  <Key>uploads/#{upload_id}/new_transcript.pdf</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
      end

      context 'with a valid transcript file upload' do
        let(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_transcript.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'application/xml'},
              body: <<~XML)
                <CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_transcript',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          store_stub
        end

        include_examples 'backward-compatible S3-upload'

        it 'updates the transcript_uri on the video' do
          store_video
          expect(video.reload.transcript_uri).not_to eq transcript_uri
          expect(video.reload.transcript_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_transcript.pdf})
        end

        it 'deletes the old file' do
          expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(transcript_uri)
        end
      end

      context 'with an invalid transcript file upload' do
        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_transcript',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          include_examples 'does not update the attachment', :transcript_uri
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          include_examples 'does not update the attachment', :transcript_uri
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'video_transcript',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_transcript.pdf})
              .to_return(status: 403)
          end

          include_examples 'does not update the attachment', :transcript_uri
        end
      end

      context 'with copied video references the same S3 reference' do
        let(:transcript_uri) { "s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/encodedUUUID/transcript.pdf" }
        let!(:store_stub) do
          stub_request(:put,
            %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_transcript.pdf})
            .to_return(
              status: 200,
              headers: {'Content-Type' => 'applhttp:ication/xml', 'Content-Disposition' => 'attachment; filename="new_transcript.pdf"'},
              body: <<~XML)
                <CopyObjectResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
                  <LastModified>2018-08-02T15:42:36.430Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </CopyObjectResult>
              XML
        end

        before do
          # Create another video with the same file reference
          create(:video, transcript_uri: video.transcript_uri)

          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_transcript',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it 'stores the transcript file in S3' do
          store_video
          expect(store_stub).to have_been_requested
        end

        it 'updates the transcript_uri on the video' do
          store_video
          expect(video.reload.transcript_uri).not_to eq transcript_uri
          expect(video.reload.transcript_uri).to match(%r{s3://xikolo-video/videos/#{UUID4(video_id).to_s(format: :base62)}/[0-9a-zA-Z]+/new_transcript.pdf})
        end

        it 'does not delete the old file' do
          expect { store_video }.not_to have_enqueued_job(S3FileDeletionJob).with(transcript_uri)
        end
      end
    end

    context 'with a request to delete the transcript' do
      let(:update_params) { {transcript_url: nil} }

      it 'clears the transcript_uri on the video' do
        expect { store_video }.to change { video.reload.transcript_uri }.from(transcript_uri).to(nil)
      end

      it 'deletes the old file' do
        expect { store_video }.to have_enqueued_job(S3FileDeletionJob).with(transcript_uri)
      end
    end

    context 'with a backward-compatible S3-upload' do
      let(:upload_id) { SecureRandom.uuid }
      let(:file_name) { 'new_transcript.pdf' }
      let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_transcript.pdf} }
      let(:purpose) { 'video_transcript' }

      before do
        store_check_stub
        upload_stub
        upload_check_stub
        store_stub
      end

      context 'via id' do
        let(:update_params) { super().merge transcript_upload_id: upload_id }

        include_examples 'backward-compatible S3-upload'
      end

      context 'via uri' do
        let(:new_uri) { "upload://#{upload_id}/#{file_name}" }
        let(:update_params) { super().merge transcript_uri: new_uri }

        include_examples 'backward-compatible S3-upload'
      end
    end
  end

  describe '(updating subtitles)' do
    let(:upload_id) { SecureRandom.uuid }
    let(:update_params) { super().merge subtitles_upload_id: upload_id }
    let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}") \
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

      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'video_subtitles',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      stub_request(:get, file_url).to_return(
        body: File.new(Rails.root.join("spec/support/files/video/subtitles/#{file_name}")),
        status: 200
      )
    end

    context 'with .vtt subtitles' do
      context 'with a valid file' do
        let(:file_name) { 'valid_en.vtt' }

        it 'update the video and creates the subtitle' do
          expect { store_video }.to change(video.subtitles, :count).from(0).to(1)
          expect(Video::SubtitleCue.count).to eq 3
        end
      end

      context 'with an invalid file' do
        let(:file_name) { 'invalid_en.vtt' }

        it 'handles the error gracefully' do
          expect { store_video }.not_to raise_error
        end

        it 'states the correct number of invalid subtitle cues' do
          store_video
          expect(video.errors.full_messages.first).to eq 'Subtitles Validation failed: Invalid subtitle cue on the WebVTT file at cue 1.'
        end

        it 'does not attach the subtitles to the video' do
          store_video
          expect(video.subtitles.count).to eq 0
          expect(Video::SubtitleCue.count).to eq 0
        end
      end

      context 'with an invalid file with multiple errors' do
        let(:file_name) { 'multiple_invalid_en.vtt' }

        it 'handles the error gracefully' do
          expect { store_video }.not_to raise_error
        end

        it 'states the correct number of invalid subtitle cues' do
          store_video
          expect(video.errors.full_messages.first).to eq 'Subtitles Validation failed: Invalid subtitle cues on the WebVTT file at cues 1, 2.'
        end

        it 'does not attach the subtitles to the video' do
          store_video
          expect(video.subtitles.count).to eq 0
          expect(Video::SubtitleCue.count).to eq 0
        end
      end

      context 'with an invalid file name' do
        let(:file_name) { 'valid.vtt' }

        it 'handles the error gracefully' do
          expect { store_video }.not_to raise_error
        end

        it 'states the correct number of invalid subtitle cues' do
          store_video
          expect(video.errors.full_messages.first).to eq 'Subtitles Missing language code in the WebVTT file name.'
        end

        it 'does not attach the subtitles to the video' do
          store_video
          expect(video.subtitles.count).to eq 0
          expect(Video::SubtitleCue.count).to eq 0
        end
      end
    end
  end

  # Updating the description is covered in request/course/items/update_spec
end
