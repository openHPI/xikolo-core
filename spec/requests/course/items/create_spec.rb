# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Items: Create', type: :request do
  subject(:create_item) do
    post "/courses/#{course['course_code']}/sections/#{section['id']}/items",
      params:,
      headers:
  end

  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:course) { create(:course, course_code: 'example') }
  let(:section) { build(:'course:section', course_id: course['id']) }
  let(:params) { {} }
  let(:headers) { {} }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course['course_code']}")
      .to_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects to login page' do
      create_item
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'for logged-in user' do
    let(:user_id) { generate(:user_id) }
    let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.content.access course.content.edit] }
    let(:content_id) { SecureRandom.uuid }
    # The tags_create_stub is needed for successful item creation and actually
    # loaded in before actions for scenarios requiring it
    let(:tags_create_stub) do
      Stub.request(
        :pinboard, :post, '/implicit_tags',
        body: hash_including(name: item['id'], course_id: course['id'])
      ).to_return Stub.response(status: 201)
    end

    before do
      stub_user_request(id: user_id, permissions:)

      Stub.request(:course, :get, "/sections/#{section['id']}")
        .to_return Stub.json(section)
      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course['id'], user_id:}
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(course_id: course['id'])
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/sections',
        query: {course_id: course['id']}
      ).to_return Stub.json([section])
      Stub.request(
        :course, :get, '/items',
        query: hash_including(section_id: section['id'])
      ).to_return Stub.json([])

      Stub.service(:pinboard, build(:'pinboard:root'))
    end

    context 'with insufficient content editor permissions' do
      let(:permissions) { [] }

      it 'redirects to root' do
        create_item
        expect(response).to redirect_to '/'
      end
    end

    shared_examples 'properly created content and item resources' do
      before { tags_create_stub }

      it 'creates the item and its content resource' do
        create_item

        expect(content_create_stub).to have_been_requested.once
        expect(item_create_stub).to have_been_requested.once
        expect(content_delete_stub).not_to have_been_requested

        expect(tags_create_stub).to have_been_requested.once

        expect(response).to redirect_to "/courses/#{course['course_code']}/sections"
      end
    end

    shared_examples 'failing content resource creation' do
      it 're-renders the creation form' do
        create_item

        expect(content_create_stub).to have_been_requested
        expect(item_create_stub).not_to have_been_requested

        expect(response).to render_template :new
      end
    end

    shared_examples 'failing item resource creation' do
      context 'with error while persisting the item resource' do
        let(:item_create_stub) do
          Stub.request(
            :course, :post, '/items',
            body: hash_including(
              params[:xikolo_course_item].merge(
                content_id:,
                section_id: section['id']
              )
            )
          ).to_return Stub.json(
            {errors: {submission_deadline: 'required_when_proctored'}},
            status: 422
          )
        end

        it 'rolls back' do
          create_item

          expect(content_create_stub).to have_been_requested.once
          expect(item_create_stub).to have_been_requested.once

          expect(content_delete_stub).to have_been_requested.once

          expect(response).to redirect_to "/courses/#{course['course_code']}/sections/#{section['id']}/items/new"
        end
      end
    end

    context 'for richtext item' do
      let(:richtext_params) { {text: 'Richtext text', course_id: course['id']} }
      let(:item) do
        build(:'course:item', content_type: 'rich_text', open_mode: false)
      end
      let(:params) do
        {
          xikolo_course_item: {
            title: item['title'],
            content_type: item['content_type'],
          },
          course_richtext: richtext_params,
        }
      end
      let(:item_create_stub) do
        Stub.request(
          :course, :post, '/items',
          body: hash_including(
            params[:xikolo_course_item].merge(
              section_id: section['id']
            )
          )
        ).to_return Stub.json({id: item['id']}, status: 201)
      end
      let(:content_delete_stub) do
        Stub.request(:course, :delete, "/richtexts/#{content_id}")
          .to_return Stub.response(status: 200)
      end

      before do
        tags_create_stub
        item_create_stub
      end

      context 'with valid params' do
        it 'creates the item and its content resource' do
          expect { create_item }.to change(Course::Richtext, :count).from(0).to(1)
          expect(item_create_stub).to have_been_requested.once
          expect(tags_create_stub).to have_been_requested.once
          expect(response).to redirect_to "/courses/#{course['course_code']}/sections"
        end
      end

      context 'with an error while persisting the content resource' do
        context 'with a rejected file in the text' do
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

          let(:richtext_params) do
            {
              text: 'Richtext with an invalid upload upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg',
              course_id: course['id'],
            }
          end

          it 're-renders the creation form and displays an error message for the file upload' do
            expect { create_item }.not_to change(Course::Richtext, :count)
            expect(item_create_stub).not_to have_been_requested
            expect(response).to render_template(:new)
            expect(response.body).to have_css('.has-error', text: 'Your file upload has been rejected due to policy violations.')
            expect(flash[:error]).to include('Something went wrong while creating this item.')
            expect(response.body).to include('upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg')
          end
        end

        context 'with a missing text attribute' do
          let(:richtext_params) { {course_id: course['id']} }

          it 're-renders the creation form' do
            expect { create_item }.not_to change(Course::Richtext, :count)
            expect(item_create_stub).not_to have_been_requested
            expect(response).to render_template(:new)
            expect(response.body).to have_css('.has-error', text: "The text can't be blank.")
            expect(flash[:error]).to include('Something went wrong while creating this item.')
          end
        end
      end
    end

    context 'for video items' do
      let(:item) { build(:'course:item', :video, open_mode: false, content_id: nil) }
      let!(:stream) { create(:stream) }
      let(:description) { 'This is the video description.' }
      let(:video_params) do
        {video: {
          description:,
          lecturer_stream_id: stream.id,
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
      let(:item_create_stub) do
        Stub.request(
          :course, :post, '/items',
          body: hash_including(
            params[:xikolo_course_item].merge(
              section_id: section['id']
            )
          )
        ).to_return Stub.json({id: item['id']}, status: 201)
      end

      before do
        item_create_stub
        tags_create_stub
      end

      it 'creates the video item' do
        expect { create_item }.to change(Video::Video, :count).from(0).to(1)
        expect(item_create_stub).to have_been_requested.once
      end

      it "sets the video's title to the item's title" do
        create_item
        expect(Video::Video.first.title).to eq item['title']
      end

      context 'with invalid video params' do
        let(:video_params) do
          {video: {
            description: 'This is the description', # None of the streams are provided
          }}
        end

        it 're-renders the creation form' do
          expect { create_item }.not_to change(Video::Video, :count).from(0)
          expect(item_create_stub).not_to have_been_requested
          expect(response).to render_template :new
          expect(response.body).to include 'We found some errors. Please review your form input.'
          expect(response.body).to have_css('.has-error', text: 'At least one of these streams is required. Please add a pip, a lecturer or a slides stream')
          expect(response.body).to include 'This is the description'
        end
      end

      context 'with an error while persisting the video resource' do
        context 'with a rejected file in the description' do
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

          let(:video_params) do
            {video: {
              description: 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg',
            }}
          end

          it 're-renders the creation form' do
            expect { create_item }.not_to change(Video::Video, :count).from(0)
            expect(item_create_stub).not_to have_been_requested
            expect(response).to render_template :new
            expect(response.body).to include 'We found some errors. Please review your form input.'
            expect(response.body).to have_css('.has-error', text: 'Your file upload has been rejected due to policy violations.')
            expect(response.body).to include 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo_bar.jpg'
          end
        end

        context 'with a rejected file among the additional files' do
          let(:upload_id) { 'b5f99337-224f-40f5-aa82-44ee8b272579' }
          let(:video_params) do
            {video: {
              lecturer_stream_id: stream.id,
              reading_material_upload_id: upload_id,
              description: 'This is a description',
            }}
          end

          before do
            stub_request(
              :head,
              'https://s3.xikolo.de/xikolo-uploads/' \
              'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/reading_material.pdf'
            ).and_return(
              status: 200,
              headers: {
                'X-Amz-Meta-Xikolo-Purpose' => 'video_reading_material',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
            stub_request(:get,
              'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
              "prefix=uploads/#{upload_id}")
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
                      <Key>uploads/#{upload_id}/reading_material.pdf</Key>
                      <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                      <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                    </Contents>
                  </ListBucketResult>
                XML
          end

          it 're-renders the creation form' do
            expect { create_item }.not_to change(Video::Video, :count).from(0)
            expect(item_create_stub).not_to have_been_requested
            expect(response).to render_template :new
            expect(response.body).to include 'We found some errors. Please review your form input.'
            expect(response.body).to have_css('.has-error', text: 'Your file upload could not be stored.')
            expect(response.body).to include 'This is a description'
          end
        end

        # Invalid subtitles are covered in operation/video/store_spec
      end

      context 'with an error while persisting the item resource' do
        let(:item_create_stub) do
          Stub.request(
            :course, :post, '/items',
            body: hash_including(
              params[:xikolo_course_item].merge(
                section_id: section['id']
              )
            )
          ).to_return Stub.json(
            # This is not actually required for video items, but just a dummy error to test the correct behaviour
            {errors: {submission_deadline: 'required_when_proctored'}},
            status: 422
          )
        end

        it 'redirects to the item new view' do
          create_item
          expect(item_create_stub).to have_been_requested
          expect(response).to redirect_to "/courses/#{course['course_code']}/sections/#{section['id']}/items/new"
          expect(flash[:error]).to include 'You must provide a submission deadline for proctored items.'
        end
      end

      context 'with an additional file upload via URI' do
        let(:upload_id) { SecureRandom.uuid }
        let(:file_name) { 'new_reading_material.pdf' }
        let(:reading_material_uri) { "upload://#{upload_id}/#{file_name}" }
        let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-video/videos/[0-9a-zA-Z]+/[0-9a-zA-Z]+/new_reading_material.pdf} }

        let(:video_params) do
          {video: {
            lecturer_stream_id: stream.id,
            reading_material_uri:,
            description:,
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

        it 'creates the video item' do
          expect { create_item }.to change(Video::Video, :count).from(0).to(1)
          expect(item_create_stub).to have_been_requested.once
          expect(store_stub).to have_been_requested.once
        end
      end
    end

    context 'for quiz items' do
      let(:item) do
        build(:'course:item', content_type: 'quiz', open_mode: false)
      end
      let(:params) do
        {
          xikolo_course_item: {
            title: item['title'],
            content_type: item['content_type'],
          },
          xikolo_quiz_quiz: {
            instructions: 'These are the quiz instructions.',
          },
        }
      end
      let(:content_create_stub) do
        Stub.request(
          :quiz, :post, '/quizzes',
          body: hash_including(params[:xikolo_quiz_quiz])
        ).to_return Stub.json({id: content_id}, status: 201)
      end
      let(:item_create_stub) do
        Stub.request(
          :course, :post, '/items',
          body: hash_including(
            params[:xikolo_course_item].merge(
              content_id:,
              section_id: section['id']
            )
          )
        ).to_return Stub.json({id: item['id']}, status: 201)
      end
      let(:content_delete_stub) do
        Stub.request(:quiz, :delete, "/quizzes/#{content_id}")
          .to_return Stub.response(status: 200)
      end

      before do
        Stub.service(:quiz, build(:'quiz:root'))

        content_create_stub
        item_create_stub
        content_delete_stub
      end

      context 'properly created content and item resources' do
        before { tags_create_stub }

        it 'creates the item and its content resource and properly adjusts the redirect' do
          create_item

          expect(content_create_stub).to have_been_requested.once
          expect(item_create_stub).to have_been_requested.once
          expect(content_delete_stub).not_to have_been_requested

          expect(tags_create_stub).to have_been_requested.once

          # The redirect path is modified for quiz items
          expect(response).to redirect_to "/courses/#{course['course_code']}/sections/#{section['id']}/items/#{item['id']}/edit"
        end
      end

      context 'with error while persisting the content resource' do
        let(:content_create_stub) do
          Stub.request(
            :quiz, :post, '/quizzes',
            body: hash_including(params[:xikolo_quiz_quiz])
          ).to_return Stub.json({errors: {base: ['invalid']}}, status: 422)
        end

        it_behaves_like 'failing content resource creation'
      end

      include_examples 'failing item resource creation'
    end

    context 'for LTI exercise items' do
      let(:item) do
        build(:'course:item', content_type: 'lti_exercise', open_mode: false)
      end
      let(:params) do
        {
          xikolo_course_item: {
            title: item['title'],
            content_type: item['content_type'],
          },
          lti_exercise: {
            instructions: 'These are the LTI instructions.',
            lti_provider_id: SecureRandom.uuid,
          },
        }
      end
      let(:item_create_stub) do
        Stub.request(
          :course, :post, '/items',
          body: hash_including({})
        ).to_return Stub.json({id: item['id']}, status: 201)
      end

      before do
        item_create_stub
        tags_create_stub
      end

      it 'creates the item and its content resource' do
        expect { create_item }.to change(Lti::Exercise, :count).from(0).to(1)
        expect(Lti::Exercise.first).to match an_object_having_attributes(
          lti_provider_id: params[:lti_exercise][:lti_provider_id]
        )
        expect(Lti::Exercise.first.instructions.to_s).to eq params[:lti_exercise][:instructions]

        expect(item_create_stub.with(
          body: hash_including(
            params[:xikolo_course_item].merge(
              content_id: Lti::Exercise.first.id,
              section_id: section['id']
            )
          )
        )).to have_been_requested.once
        expect(tags_create_stub).to have_been_requested.once

        expect(response).to redirect_to "/courses/#{course['course_code']}/sections"
      end

      context 'with invalid attributes for the content resource' do
        let(:params) do
          super().merge(lti_exercise: {
            instructions: 'These are the LTI instructions.',
            lti_provider_id: nil,
          })
        end

        it 're-renders the creation form' do
          expect { create_item }.not_to change(Lti::Exercise, :count).from(0)

          expect(item_create_stub).not_to have_been_requested

          expect(response).to render_template :new
        end

        it 'shows validation message' do
          create_item

          expect(response.body).to include('can&#39;t be blank')
        end
      end

      context 'with error while persisting the item resource' do
        let(:item_create_stub) do
          Stub.request(
            :course, :post, '/items',
            body: hash_including(
              params[:xikolo_course_item].merge(section_id: section['id'])
            )
          ).to_return Stub.json(
            {errors: {submission_deadline: 'required_when_proctored'}},
            status: 422
          )
        end

        it 'rolls back the content creation' do
          expect { create_item }.not_to change(Lti::Exercise, :count).from(0)

          expect(item_create_stub).to have_been_requested.once

          expect(response).to redirect_to "/courses/#{course['course_code']}/sections/#{section['id']}/items/new"
        end
      end
    end
  end
end
