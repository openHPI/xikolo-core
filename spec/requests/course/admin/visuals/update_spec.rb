# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Visuals: Update', type: :request do
  subject(:update_visual) do
    patch "/courses/#{course.id}/visual", params:, headers:
  end

  let(:params) { {course_visual: {image_upload_id: upload_id}} }
  let(:headers) { {} }

  let(:course) { create(:course) }
  let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
  let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
  let(:image_url) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }
  let(:stream) { create(:stream) }
  let(:file_name) { 'image.png' }

  # S3 related stubs
  let(:list_stub) do
    stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{upload_id}")
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
  let(:read_stub) do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_course_image',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:store_stub) do
    stub_request(:put, image_url).to_return(status: 200, body: '<xml></xml>')
  end

  before do
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(
        build(:'course:course', id: course.id, course_code: course.course_code)
      )
  end

  context 'for logged-in users' do
    let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permission' do
      let(:permissions) { %w[course.course.edit course.content.access] }

      before do
        list_stub
        read_stub
        store_stub
      end

      context 'with a not yet existing course visual' do
        it 'creates the course visual' do
          expect { update_visual }.to change(Course::Visual, :count).from(0).to(1)
          expect(response).to redirect_to "/courses/#{course.course_code}/visual/edit"
        end

        it 'stores the course image' do
          update_visual
          expect(store_stub).to have_been_requested
          expect(course.visual.image_url).to match image_url
        end

        context 'when showing the course after update' do
          let(:params) { super().merge(show: true) }

          it 'redirects to the course page' do
            update_visual
            expect(response).to redirect_to "/courses/#{course.course_code}"
          end
        end
      end

      context 'with an existing course image' do
        let(:old_image_uri) { 's3://xikolo-public/courses/1/42/old_image.png' }

        before do
          create(:visual, course:, image_uri: old_image_uri)
        end

        it 'updates the existing course image' do
          expect { update_visual }.to change { course.visual.reload.image_url }
            .from(%r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/old_image.png})
            .to(%r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/image.png})
          expect(store_stub).to have_been_requested
        end

        it 'does not create a new course visual' do
          expect { update_visual }.not_to change(Course::Visual, :count).from(1)
        end

        context 'when the course image is requested to be removed' do
          let(:params) { {course_visual: {delete_image: true}} }

          it 'removes the course image' do
            expect { update_visual }.to change { course.visual.reload.image_uri }
              .from(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/old_image.png})
              .to(nil)
          end

          it 'schedules the removal of the corresponding S3 file' do
            expect { update_visual }.to have_enqueued_job(S3FileDeletionJob).with(old_image_uri)
          end
        end

        context 'when replacing the course image with a teaser video' do
          let(:params) { {course_visual: {delete_image: true, video_stream_id: stream.id}} }

          it 'removes the course image' do
            expect { update_visual }.to change { course.visual.reload.image_uri }
              .from(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/old_image.png})
              .to(nil)
          end

          it 'schedules the removal of the corresponding S3 file' do
            expect { update_visual }.to have_enqueued_job(S3FileDeletionJob).with(old_image_uri)
          end

          it 'creates the course teaser video' do
            expect { update_visual }.to change { course.visual.reload.video_stream }
              .from(nil)
              .to(stream)
          end
        end
      end

      context 'with an existing course teaser video' do
        let(:video) { create(:video, :kaltura) }

        before do
          create(:visual, :with_video, course:, video:)
        end

        context 'when the course teaser video is requested to be removed' do
          let(:params) { {course_visual: {video_stream_id: nil}} }

          it 'removes the course teaser video' do
            expect { update_visual }.to change { course.visual.reload.video_stream }
              .from(video.pip_stream)
              .to(nil)
          end

          it 'does not remove the course image' do
            expect { update_visual }.not_to change { course.visual.reload.image_url }
          end
        end

        context 'when attaching subtitles to the teaser video' do
          let(:params) { {course_visual: {subtitles_upload_id:, video_stream_id: stream.id}} }
          let(:subtitles_upload_id) { generate(:uuid) }
          let(:file_name) { 'video-subtitles.zip' }
          let(:subtitles_file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{subtitles_upload_id}/#{file_name}" }

          let(:list_stub) do
            stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{subtitles_upload_id}")
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
                      <Key>uploads/#{subtitles_upload_id}/#{file_name}</Key>
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
          let(:upload_request) do
            stub_request(:get, subtitles_file_url).to_return(
              body: File.new(Rails.root.join("spec/support/files/video/subtitles/#{file_name}")),
              status: 200
            )
          end

          before do
            upload_request
            list_stub
            read_stub
          end

          it 'processes the upload of the subtitles' do
            update_visual
            expect(video.reload.subtitles).not_to be_empty
            expect(video.reload.subtitles.pluck(:lang)).to contain_exactly('de', 'en')
          end

          context 'when the subtitles cannot be processed' do
            let(:params) { {course_visual: {subtitles_upload_id:, video_stream_id: stream.id}} }
            let(:file_name) { 'invalid-video-subtitles.zip' }

            it 'raises an error' do
              update_visual
              expect(video.reload.subtitles).to be_empty
              expect(flash[:error].first).to eq 'The subtitles could not be uploaded, please check their format and try again.'
            end
          end

          context 'without a selected course teaser video' do
            let(:params) { {course_visual: {subtitles_upload_id:}} }

            it 'raises an error' do
              update_visual
              expect(video.reload.subtitles).to be_empty
              expect(flash[:error].first).to eq 'Subtitles were added for the teaser video, but no video file was found. Please add a teaser video.'
            end
          end
        end
      end

      context 'when creating / updating both the course image and teaser video at once' do
        let(:params) { {course_visual: {video_stream_id: stream.id, image_upload_id: upload_id}} }

        it 'creates the course visual' do
          expect { update_visual }.to change(Course::Visual, :count).from(0).to(1)
          expect(response).to redirect_to "/courses/#{course.course_code}/visual/edit"
        end

        it 'stores the course image' do
          update_visual
          expect(store_stub).to have_been_requested
          expect(course.visual.image_url).to match image_url
        end

        it 'creates the course teaser video' do
          update_visual
          expect(course.visual.video_stream.id).to eq params[:course_visual][:video_stream_id]
        end
      end
    end

    context 'without permission' do
      let(:permissions) { %w[course.content.access] }

      it 'does not allow creating / updating the visual' do
        expect { update_visual }.not_to change(Course::Visual, :count).from(0)
        expect(response).to redirect_to root_url
        expect(flash[:error].first).to eq 'You do not have sufficient permissions for this action.'
      end
    end
  end

  context 'for anonymous users' do
    it 'does not allow creating / updating the visual' do
      expect { update_visual }.not_to change(Course::Visual, :count).from(0)
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
