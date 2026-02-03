# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Update', type: :request do
  subject(:action) do
    put("/courses/#{course.course_code}/sections/#{section['id']}/items/#{item.id}",
      params:,
      headers:)
    response
  end

  let(:course) { create(:course, course_code: 'example') }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:section) { build(:'course:section', course_id: course.id) }
  let(:item) { create(:item) }
  let(:item_resource) { build(:'course:item', id: item.id) }
  let(:params) { {} }
  let(:headers) { {} }

  before do
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    let(:item_resource) { build(:'course:item') }

    it 'redirects to login page' do
      expect(action).to be_redirect
      expect(action).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'for a logged in user' do
    let(:user_id) { generate(:user_id) }
    let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.content.access course.content.edit] }
    let(:update_stub) { Stub.request(:course, :put, "/items/#{item.id}").to_return Stub.json(item_resource) }

    before do
      stub_user_request(id: user_id, permissions:)
      Stub.request(
        :course, :get, "/items/#{item.id}"
      ).to_return Stub.json(item_resource)
      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, user_id:}
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(course_id: course.id)
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/items',
        query: hash_including(section_id: section['id'])
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/sections',
        query: {course_id: course.id}
      ).to_return Stub.json([section])
      Stub.request(
        :course, :get, "/sections/#{section['id']}"
      ).to_return Stub.json(section)
      update_stub
    end

    context 'for LTI items' do
      let(:item) { create(:item, :lti_exercise) }
      let(:item_resource) { build(:'course:item', :lti_exercise, id: item.id, content_id: item.content_id) }
      let(:params) do
        {
          xikolo_course_item: {
            title: item.title,
            content_type: item.content_type,
          },
          lti_exercise: exercise_params,
        }
      end

      context 'when the item content is invalid' do
        let(:exercise_params) do
          {
            instructions: 'These are the LTI instructions.',
            lti_provider_id: nil,
          }
        end

        it 'shows validation message' do
          expect(action.body).to include('can&#39;t be blank')
        end
      end

      context 'when the item content is valid' do
        let(:exercise_params) do
          {
            instructions: 'These are the LTI instructions.',
            lti_provider_id: item.content.lti_provider_id,
          }
        end

        it 'redirects to the edit page' do
          expect(action).to redirect_to edit_course_section_item_path
        end
      end
    end

    context 'for video items' do
      let(:item_resource) { build(:'course:item', :video, id: item.id, content_id: video.id, open_mode: false) }
      let(:item) { create(:item, content: video) }
      let(:video) { create(:video) }
      let(:video_params) do
        {video: {
          pip_stream_id: video.pip_stream.id,
        }}
      end

      let(:params) do
        {
          xikolo_course_item: {
            title: item.title,
            content_type: item.content_type,
          },
        }.merge(video_params)
      end

      before do
        allow_any_instance_of(Video::Video).to receive(:id).and_return video.id # rubocop:disable RSpec/AnyInstance
      end

      shared_examples 'displays generic and specific error messages' do |specific_error|
        it 'displays a generic error message at the top of the page' do
          action
          expect(flash[:error]).to include 'Something went wrong while updating this item.'
        end

        it 'displays a specific error message near the related field' do
          action
          expect(response.body).to include 'We found some errors. Please review your form input.'
          expect(response.body).to have_css('.has-error', text: specific_error)
        end
      end

      it 'updates the video item' do
        action
        expect(Video::Video.first).to match an_object_having_attributes(
          lecturer_stream_id: params[:video][:lecturer_stream_id]
        )
      end

      context 'with invalid video params (i.e. no streams)' do
        let(:video_params) do
          {video: {
            description: 'This is the video description.',
            pip_stream_id: nil,
          }}
        end

        # Description: Your file upload could not be stored.
        specific_error = 'At least one of these streams is required. Please add a pip, a lecturer or a slides stream.'
        it_behaves_like 'displays generic and specific error messages', specific_error

        it 'does not update the video item' do
          action
          expect(Video::Video.first.reload).to eq video
          expect(Video::Video.first.description.to_s).to eq 'Video for testing.'
        end
      end

      context 'with an invalid item' do
        let(:update_stub) do
          Stub.request(:course, :put, "/items/#{item.id}")
            .to_return Stub.json({errors: {title: "can't be blank"}}, status: 422)
        end

        it 'does not update the video item' do
          action
          expect(Video::Video.first.reload).to eq video
          expect(Video::Video.first.description.to_s).to eq 'Video for testing.'
        end

        it 'displays an error message' do
          action
          expect(flash[:error]).to include 'The item title must not be blank.'
        end
      end

      context '(updating description)' do
        let(:video_id) { SecureRandom.uuid }
        let(:video) { create(:video, id: video_id, description: old_description) }
        let(:old_file_uri) { "s3://xikolo-video/videos/#{video_id}/rtfiles/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg" }
        let(:old_file_url) { "https://s3.xikolo.de/xikolo-video/videos/#{video_id}/rtfiles/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg" }
        let(:old_description) { "Some Text with a file: #{old_file_uri}" }
        let(:video_params) do
          {video: {
            description: 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg',
          }}
        end
        let(:store_regex) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/foo_bar.jpg}x }
        let!(:store_stub) do
          stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
        end

        before do
          stub_request(:head, store_regex).and_return(status: 404)
        end

        context 'with a valid description with valid files' do
          before do
            stub_request(
              :head,
              'https://s3.xikolo.de/xikolo-uploads/' \
              'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg'
            ).and_return(
              status: 200,
              headers: {
                'X-Amz-Meta-Xikolo-Purpose' => 'video_description',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
          end

          it 'stores the file in the description' do
            action
            expect(store_stub).to have_been_requested
          end

          it 'updates the description on the video' do
            action
            expect(Video::Video.first[:description].to_s).to start_with("s3://xikolo-video/videos/#{UUID4(video_id).to_str(format: :base62)}/rtfiles")
              .and end_with 'foo_bar.jpg'
          end

          it 'deletes the old file' do
            expect { action }.to have_enqueued_job(S3FileDeletionJob).with(old_file_uri)
          end
        end

        context 'with an invalid file in the description' do
          before do
            stub_request(
              :head,
              'https://s3.xikolo.de/xikolo-uploads/' \
              'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg'
            ).and_return(
              status: 200,
              headers: {
                'X-Amz-Meta-Xikolo-Purpose' => 'video_description',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          specific_error = 'Your file upload has been rejected due to policy violations.'
          it_behaves_like 'displays generic and specific error messages', specific_error

          it 'does not update the description' do
            action
            expect(Video::Video.first[:description].to_s).to eq old_description
          end

          it 'does not delete the file in the old description' do
            expect { action }.not_to have_enqueued_job(S3FileDeletionJob).with(old_file_uri)
          end
        end

        context 'with a storage error' do
          let(:store_stub) do
            stub_request(:put, store_regex).and_return(status: 503)
          end

          before do
            store_stub
            stub_request(
              :head,
              'https://s3.xikolo.de/xikolo-uploads/' \
              'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg'
            ).and_return(
              status: 200,
              headers: {
                'X-Amz-Meta-Xikolo-Purpose' => 'video_description',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
          end

          specific_error = 'Your file upload could not be stored.'
          it_behaves_like 'displays generic and specific error messages', specific_error

          it 'does not update the description' do
            action
            expect(Video::Video.first[:description].to_s).to eq old_description
          end

          it 'does not delete the file in the old description' do
            expect { action }.not_to have_enqueued_job(S3FileDeletionJob).with(old_file_uri)
          end
        end
      end
      # Invalid subtitles and additional files are covered in operation/video/store_spec

      context 'with an additional file upload via URI' do
        let(:upload_id) { SecureRandom.uuid }
        let(:file_name) { 'new_reading_material.pdf' }
        let(:reading_material_uri) { "upload://#{upload_id}/#{file_name}" }
        let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf} }
        let(:new_reading_material_uri) { %r{s3://xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf} }

        let(:video_params) do
          {video: {
            reading_material_uri:,
          }}
        end
        let(:params) do
          {
            xikolo_course_item: {
              title: item['title'],
              content_type: item['content_type'],
            },
          }.merge(video_params)
        end
        let(:store_stub) do
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
          stub_request(
            :head,
            "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/new_reading_material.pdf"
          ).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'video_material',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          stub_request(:head, store_stub_url).and_return(status: 404)
          store_stub
        end

        it 'updates the video item' do
          action
          expect(Video::Video.first).to match an_object_having_attributes(
            reading_material_uri: new_reading_material_uri
          )
        end
      end
    end

    context 'for richtext items' do
      let(:richtext) { create(:richtext, course_id: course.id) }
      let(:item_resource) { build(:'course:item', id: item.id, content_id: richtext.id, section_id: section['id'], content_type: 'rich_text') }
      let(:item) { create(:item, content_id: richtext.id, content_type: 'rich_text') }
      let(:params) do
        {
          xikolo_course_item: {
            title: item.title,
            content_type: item.content_type,
          },
          course_richtext: {
            text:,
          },
        }
      end

      context 'with an error while persisting the content resource' do
        context 'with an empty text attribute' do
          let(:text) { '' }

          it 'shows the error flash message' do
            expect(action).to render_template(:edit)
            expect(flash[:error]).to include('Something went wrong while updating this item.')
            expect(response.body).to have_css('.has-error', text: "The text can't be blank")
          end
        end

        context 'with a rejected file in the text' do
          let(:text) { 'Richtext description with an invalid upload upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg' }

          before do
            stub_request(
              :head,
              'https://s3.xikolo.de/xikolo-uploads/' \
              'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg'
            ).and_return(
              status: 200,
              headers: {
                'X-Amz-Meta-Xikolo-Purpose' => 'course_richtext',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          it 're-renders the edit form and displays an error message for the file upload' do
            expect { action }.not_to change(Course::Richtext, :count)
            expect(update_stub).to have_been_requested
            expect(response).to render_template(:edit)
            expect(response.body).to have_css('.has-error', text: 'Your file upload has been rejected due to policy violations.')
            expect(flash[:error]).to include('Something went wrong while updating this item.')
            expect(response.body).to include('upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg')
            expect(richtext.reload.text.to_s).to eq('Text')
          end
        end
      end

      context 'when updating an existing richtext item' do
        let(:richtext) { create(:richtext, text: existing_text) }
        let(:file_uri) { 's3://xikolo-public/richtexts/2HdilJQuvQYPVktWuS7qrB/richtext_image.png' }
        let(:existing_text) { "![enter file description here] A text with file\r\n\r\n\r\n  #{file_uri}" }

        context 'with a new text having the same file referenced' do
          let(:text) { "![A nice file description] A text with file\r\n\r\n\r\n  #{file_uri} and some more text" }

          before do
            action
          end

          it 'updates the text only' do
            expect(richtext.reload.text.to_s).to eq(text)
          end

          it 'does not delete the referenced file from S3 bucket' do
            expect { action }.not_to have_enqueued_job(S3FileDeletionJob)
          end
        end

        context 'file reference (but not the text)' do
          let(:uri_regex) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/#{file_name}}x }
          let(:new_upload_id) { '56cd8d3282a0-d464-4574-b518-ecfde9ec' }
          let(:file_name) { 'new_richtext_image.png' }
          let(:text) { "Markup description\r\n\r\n![Insert image description](upload://#{new_upload_id}/#{file_name})" }

          let(:upload_stub) { stub_request(:put, uri_regex).and_return(status: 200, body: '<xml></xml>') }
          let(:check_target_stub) { stub_request(:head, uri_regex).and_return(status: 404) }
          let(:read_upload_stub) do
            stub_request(:head, "https://s3.xikolo.de/xikolo-uploads/uploads/#{new_upload_id}/#{file_name}")
              .and_return(
                status: 200,
                headers: {
                  'Content-Type' => 'inode/x-empty',
                  'X-Amz-Meta-Xikolo-Purpose' => 'course_richtext',
                  'X-Amz-Meta-Xikolo-State' => 'accepted',
                }
              )
          end

          before do
            check_target_stub
            read_upload_stub
            upload_stub
          end

          it 'updates the file reference only' do
            action
            expect(richtext.reload.text.to_s).to match(%r{s3://xikolo-public/courses/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/new_richtext_image.png}x)
            expect(upload_stub).to have_been_requested
          end

          it 'removes the old file from' do
            expect { action }.to have_enqueued_job(S3FileDeletionJob).with(file_uri)
          end

          context 'the file is referenced in a course description' do
            let(:course) { create(:course, description: "The focus of this lecture is on this file: #{file_uri}") }

            it 'does not schedule the file deletion' do
              course
              expect { action }.not_to have_enqueued_job(S3FileDeletionJob)
            end
          end
        end
      end
    end

    context 'when removing a required item' do
      let(:required_item) { create(:item) }
      let(:item) { create(:item, required_item_ids: [required_item.id]) }
      let(:update_stub) do
        Stub.request(:course, :put, "/items/#{item.id}",
          body: hash_including(required_item_ids: [])).to_return Stub.json(item_resource)
      end

      context 'with hidden field' do
        let(:params) do
          {xikolo_course_item: {title: item.title, required_item_ids: ['']}}
        end

        it 'removes the required item' do
          action
          expect(update_stub).to have_been_requested
        end
      end

      context 'without hidden field' do
        let(:params) do
          {xikolo_course_item: {title: item.title}}
        end

        it 'removes the required item' do
          action
          expect(update_stub).to have_been_requested
        end
      end
    end
  end
end
