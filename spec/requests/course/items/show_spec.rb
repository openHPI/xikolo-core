# frozen_string_literal: true

require 'spec_helper'

shared_examples 'an item with a manipulated URL' do
  context "when the item's course and the course in the URL does not match" do
    subject(:show_item) { get "/courses/tatort/items/#{item.id}", headers: }

    let(:other_course) { build(:'course:course', course_code: 'tatort') }

    before do
      Stub.request(:course, :get, '/courses/tatort').to_return Stub.json(other_course)
      Stub.request(:course, :get, '/sections', query: {course_id: other_course['id']})
        .to_return Stub.json([build(:'course:section', id: section.id, course_id: other_course['id'])])
    end

    it 'responds with 404 Not Found' do
      expect { show_item }.to raise_error(Status::NotFound)
    end
  end
end

shared_examples 'an inaccessible item' do |error|
  it 'redirects' do
    show_item
    expect(create_visit_request).not_to have_been_requested
    expect(response).to redirect_to redirect_target
    expect(request.flash[:error].first).to eq error if error
  end
end

shared_examples 'an accessible item' do |enrolled: true, quiz: false|
  it 'shows the item' do
    show_item
    expect(response).to have_http_status(:ok)
    expect(response.body).to include item.title
  end

  it 'shows the content of the item', unless: quiz do
    show_item
    expect(response.body).to include type_specific_content
  end

  it 'does not show the content of the item', if: quiz do
    show_item
    expect(response.body).not_to include type_specific_content
  end

  it 'creates a visit', unless: quiz do
    show_item
    expect(create_visit_request).to have_been_requested
  end

  # The QuizSubmissionController takes care of creating visits for quizzes
  it 'does not create a visit', if: quiz do
    show_item
    expect(create_visit_request).not_to have_been_requested
  end

  it 'shows an enrollment notice', if: !enrolled && quiz do
    show_item
    expect(response.body).to include 'You are not enrolled. Please enroll to see this quiz.'
  end

  it 'does not show an enrollment notice', if: enrolled || !quiz do
    show_item
    expect(response.body).not_to include 'You are not enrolled. Please enroll to see this quiz.'
  end
end

shared_examples 'an item with prerequisites' do |quiz: false|
  let(:required_item) { create(:item, content_type: 'rich_text') }
  let(:item_params) { super().merge(required_item_ids: [required_item.id]) }

  context 'with unfulfilled prerequisites' do
    it_behaves_like 'an accessible item', quiz: do
      let(:type_specific_content) { 'What is the answer?' }
    end

    it 'lists the unmet requirements' do
      show_item
      expect(response.body).to include required_item.title
      expect(response.body).to include 'Requirements not met'
    end
  end

  context 'with fulfilled prerequisites' do
    before do
      user = create(:user, id: user_id)
      create(:visit, item: required_item, user:)
    end

    # Only ungraded quizzes without any prerequisites are started automatically
    it_behaves_like 'a startable quiz' if quiz

    it_behaves_like 'an accessible item', quiz: do
      let(:type_specific_content) { 'What is the answer?' }
    end
  end
end

shared_examples 'a startable quiz' do
  it 'allows to start the quiz' do
    show_item
    expect(response.body).to include 'Start quiz now'
    expect(response.body).not_to include 'Requirements not met'
    expect(create_visit_request).not_to have_been_requested
  end
end

shared_context 'for quizzes' do
  before do
    Stub.request(:quiz, :get, "/quizzes/#{item.content_id}")
      .to_return Stub.json({id: item.content_id, current_allowed_attempts: 1})
    Stub.request(:course, :get, '/enrollments', query: {course_id: course.id, user_id:})
      .to_return Stub.json(enrollments_resources)
    Stub.request(:quiz, :get, '/questions', query: {per_page: 250, quiz_id: item.content_id})
      .to_return Stub.json(build(:'quiz:question', quiz_id: item.content_id))
  end
end

describe 'Course: Items: Show', type: :request do
  subject(:show_item) { get "/courses/#{course.course_code}/items/#{item.id}", headers: }

  let(:headers) { {} }
  let(:course) { create(:course, course_code: 'example') }
  let(:section) { create(:section, course:) }
  let(:item) { create(:item, :richtext, section:, title: 'The Item') }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item_resource) { build(:'course:item', **item_params) }
  let(:item_params) do
    {id: item.id, section_id: section.id, content_id: item.content_id, content_type: item.content_type, title: item.title}
  end
  let(:get_item_for_user_request) do
    Stub.request(:course, :get, "/items/#{item.id}", query: {user_id:})
      .to_return Stub.json(item_resource)
  end
  let(:create_visit_request) do
    Stub.request(:course, :post, "/items/#{item.id}/users/#{user_id}/visit")
  end

  before do
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates',
      query: hash_including(course_id: course.id, user_id:)).to_return Stub.json([])
    get_item_for_user_request
    create_visit_request
  end

  context 'when the user is anonymous' do
    let(:user_id) { 'anonymous' }

    it_behaves_like 'an inaccessible item', 'Please log in to proceed.' do
      let(:redirect_target) { '/courses/example' }
    end
  end

  context 'when the user is logged in' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { [] }
    let(:user_id) { generate(:user_id) }
    let(:item_resources) { [item_resource] }

    before do
      stub_user_request(id: user_id, permissions:)
      Stub.request(:account, :get, "/users/#{user_id}/preferences")
        .to_return Stub.json({properties: {}})
      Stub.request(:course, :get, '/sections', query: {course_id: course.id})
        .to_return Stub.json([section_resource])
      Stub.request(:course, :get, '/items',
        query: {published: true, section_id: section.id, state_for: user_id}).to_return Stub.json(item_resources)
      Stub.request(:course, :get, "/sections/#{section.id}").to_return Stub.json(section_resource)
      Stub.request(:course, :get, '/items', query: {section_id: section.id})
        .to_return Stub.json(item_resources)
      Stub.request(:course, :post, "/items/#{item.id}/users/#{user_id}/visit")
    end

    context 'when the user is not enrolled' do
      it_behaves_like 'an inaccessible item', 'You are not enrolled for this course.' do
        let(:redirect_target) { '/courses/example' }
      end

      context 'with a video item in open mode' do
        let(:item) { create(:item, :video, section:, title: 'The Video', open_mode: true) }
        let(:item_params) { super().merge(open_mode: item.open_mode) }

        it_behaves_like 'an accessible item', enrolled: false do
          let(:type_specific_content) { item.content.description.to_s }

          before do
            Stub.request(:pinboard, :get, '/topics', query: {item_id: item.id})
              .to_return Stub.json([])
          end
        end
      end
    end

    context 'when the user is an admin' do
      let(:permissions) { %w[course.content.access] }
      let(:get_item_for_user_request) do
        Stub.request(:course, :get, "/items/#{item.id}").to_return Stub.json(item_resource)
      end

      it_behaves_like 'an item with a manipulated URL'

      it_behaves_like 'an accessible item', enrolled: false do
        let(:type_specific_content) { item.content.text.to_s }
      end

      context 'with a quiz item' do
        let(:item) { create(:item, section:, title: 'The Quiz', content_type: 'quiz', content_id: generate(:quiz_id)) }

        include_context 'for quizzes' do
          let(:enrollments_resources) { [] }
        end

        it_behaves_like 'an accessible item', quiz: true, enrolled: false do
          let(:type_specific_content) { 'What is the answer?' }
        end

        context 'when it is unpublished' do
          let(:item) { create(:item, section:, title: 'The Quiz', content_type: 'quiz', content_id: generate(:quiz_id), published: false) }
          let(:item_params) { super().merge(published: false) }

          it_behaves_like 'an accessible item', quiz: true, enrolled: false do
            let(:type_specific_content) { 'What is the answer?' }
          end
        end
      end

      context 'with an unpublished item' do
        let(:permissions) { %w[course.content.access] }
        let(:item) { create(:item, :richtext, section:, title: 'The Item', published: false) }
        let(:item_params) { super().merge(published: false) }
        let(:another_item_resource) do
          build(:'course:item', section_id: section.id, content_type: 'quiz', title: 'The Quiz Item', published: true)
        end
        let(:item_resources) { [item_resource, another_item_resource] }

        it_behaves_like 'an accessible item' do
          let(:type_specific_content) { item.content.text.to_s }
        end

        it 'does not lock it in the navigation' do
          show_item
          expect(response.body).to include('class="course-nav-item rich_text active"')
          expect(response.body).to include('class="course-nav-item quiz"')
          expect(response.body).not_to include('class="course-nav-item rich_text active locked"')
          expect(response.body).not_to include('class="course-nav-item quiz locked"')
        end
      end
    end

    context 'when the user is enrolled in the course' do
      let(:permissions) { %w[course.content.access.available] }

      it_behaves_like 'an accessible item' do
        let(:type_specific_content) { item.content.text.to_s }
      end

      it_behaves_like 'an item with a manipulated URL'

      context 'with an unpublished item' do
        let(:item) { create(:item, :richtext, section:, title: 'The Item', published: false) }
        let(:item_params) { super().merge(published: false) }

        it_behaves_like 'an inaccessible item', nil do
          let(:redirect_target) { "/courses/#{course.id}/resume" }
        end
      end

      context 'with an item from another branch' do
        subject(:show_item) { get "/courses/example/items/#{unaccessible_item_id}", headers: }

        let(:unaccessible_item_id) { generate(:item_id) }

        before do
          Stub.request(:course, :get, "/items/#{unaccessible_item_id}")
            .to_return Stub.json([])
          Stub.request(:course, :get, "/items/#{unaccessible_item_id}", query: {user_id:})
            .to_return status: 404, headers: {}
        end

        it 'redirects to resume' do
          expect(show_item).to redirect_to course_resume_path course.id
        end
      end

      context 'with a quiz item' do
        let(:item) { create(:item, section:, title: 'The Quiz', content_type: 'quiz', content_id: generate(:quiz_id)) }
        let(:item_params) { super().merge(exercise_type: 'selftest', required_item_ids: []) }

        include_context 'for quizzes' do
          let(:enrollments_resources) { [build(:'course:enrollment', course_id: course.id, user_id:)] }

          before do
            Stub.request(:quiz, :get, '/quiz_submissions',
              query: {newest_first: true, quiz_id: item.content_id, user_id:}).to_return Stub.json([])
            Stub.request(:quiz, :get, '/user_quiz_attempts',
              query: {quiz_id: item.content_id, user_id:}).to_return Stub.json({attempts: 1, additional_attempts: 10})
          end
        end

        it 'redirects to the quiz' do
          show_item
          expect(response).to be_redirect
          expect(response.location).to include '/quiz_submission/new'
        end

        context 'with prerequisites' do
          it_behaves_like 'an item with prerequisites', quiz: true
        end

        context 'when the quiz is graded' do
          let(:item_params) { super().merge(exercise_type: 'main', required_item_ids: []) }

          it_behaves_like 'a startable quiz'

          it_behaves_like 'an item with prerequisites', quiz: true
        end
      end

      context 'with a video item' do
        let(:item) { create(:item, :video, section:) }

        before do
          Stub.request(:pinboard, :get, '/topics', query: {item_id: item.id})
            .to_return Stub.json([])
        end

        it 'sets the meta tags properly' do
          show_item
          expect(response.body).to _have_xpath '//title'
          expect(response.body).to _have_xpath "//meta[@property='og:title']"
          expect(response.body).to _have_xpath "//meta[@property='og:image']"
          expect(response.body).to _have_xpath "//meta[@property='og:type']"
          expect(response.body).to _have_xpath "//meta[@property='og:url']"
        end
      end

      context 'with an LTI exercise item' do
        let(:item) { create(:item, :lti_exercise, section:) }

        it_behaves_like 'an accessible item' do
          let(:type_specific_content) { 'Launch exercise tool' }
        end

        context 'when the exercise is graded' do
          let(:lti_gradebook) { create(:lti_gradebook, exercise: item.content, user_id:) }
          let(:item_params) { super().merge(max_points: 10.5, unlocked: true) }

          before do
            create(:lti_grade, gradebook: lti_gradebook, value: 0.25)
            create(:lti_grade, gradebook: lti_gradebook, value: 0.5)
            create(:lti_grade, gradebook: lti_gradebook, value: 0)
          end

          it 'shows the grading' do
            show_item
            expect(response.body).to include '5.25 of 10.5 points achieved'
          end
        end
      end
    end
  end
end
