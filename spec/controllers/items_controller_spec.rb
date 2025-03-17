# frozen_string_literal: true

require 'spec_helper'
require 'rspec/expectations'

describe ItemsController, type: :controller do
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:course_resource) { build(:'course:course', id: course.id, title: course.title, course_state:, context_id: course_context_id) }
  let(:section_resource) { build(:'course:section', id: section.id, title: section.title, course_id: course.id) }
  let(:item_resource) do
    build(:'course:item',
      id: item.id,
      section_id: section.id,
      title: item.title,
      content_id: item.content_id,
      content_type: item.content_type,
      published: true)
  end

  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { [] }
  let(:course_state) { 'archive' }
  let(:request_context_id) { course_context_id }

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}'
    )
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      section_url: '/sections/{id}',
      sections_url: '/sections',
      item_url: '/items/{id}',
      items_url: '/items'
    )

    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .to_return Stub.json({properties: {}})
    Stub.request(
      :account, :get, "/users/#{user_id}/permissions",
      query: {context: 'root', user_id:}
    ).to_return Stub.json(permissions)

    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([{course_id: course.id, user_id:}])
    Stub.request(:course, :get, "/sections/#{section.id}").to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json([])
    stub_user id: user_id, permissions:
  end

  describe 'GET #new' do
    subject { get :new, params: {course_id: course.id, section_id: section.id} }

    before do
      Stub.request(:course, :get, '/items', query: {section_id: section.id, state_for: ''})
        .to_return Stub.json([])
    end

    context 'as non admin' do
      it { is_expected.to have_http_status :found }
    end

    context 'via get with course.content.edit permissions' do
      let(:request_context_id) { course_context_id }
      let(:permissions)        { %w[course.content.edit course.content.access] }

      it { is_expected.to have_http_status :ok }
    end
  end

  describe 'GET #show' do
    subject(:action) { get :show, params: {id: item.id, course_id: course.id, section_id: section.id} }

    let(:permissions) { ['course.content.access.available'] }

    before do
      Stub.request(:course, :get, "/items/#{item.id}", query: {user_id:})
        .to_return Stub.json(item_resource)
    end

    context 'with an unpublished item' do
      let(:item) { create(:item, section:, published: false) }
      let(:item_resource) do
        build(:'course:item',
          id: item.id,
          section_id: section.id,
          published: item.published)
      end

      it 'redirects' do
        expect(action).to have_http_status :found
      end
    end

    context 'with a published item' do
      before do
        Stub.request(:course, :get, '/items',
          query: {section_id: section.id, state_for: user_id, published: true}).to_return Stub.json([item_resource])
        Stub.request(
          :course, :post, "/items/#{item.id}/users/#{user_id}/visit"
        ).to_return Stub.json({item_id: item.id, user_id:})
      end

      context 'with an LTI exercise' do
        let(:item) { create(:item, :lti_exercise, section:) }
        let(:item_resource) { super().merge(max_points: 10.5, unlocked: true) }
        let(:lti_gradebook) { create(:lti_gradebook, exercise: item.content, user_id:) }

        it 'assigns all required resources' do
          action
          expect(assigns(:item_presenter)).to be_a(LtiExerciseItemPresenter)
        end

        context 'with LTI grades present' do
          before do
            create(:lti_grade, gradebook: lti_gradebook, value: 0.25)
            create(:lti_grade, gradebook: lti_gradebook, value: 0.5)
            create(:lti_grade, gradebook: lti_gradebook, value: 0)
          end

          it 'assigns the item presenter, which exposes the best score' do
            action
            presenter = assigns(:item_presenter)
            expect(presenter.score).to eq 5.25
          end

          it { is_expected.to render_template layout: 'course_area_two_cols' }
        end

        context 'without LTI grades' do
          it { is_expected.to render_template layout: 'course_area_two_cols' }
        end

        it { is_expected.to have_http_status :ok }
        it { is_expected.to render_template 'show' }
      end

      context 'with a video' do
        render_views

        let(:course_state) { 'active' }
        let(:item) { create(:item, :video, section:) }

        before do
          Stub.service(:news, build(:'news:root'))
          Stub.service(:pinboard, build(:'pinboard:root'))

          Stub.request(
            :news, :get, '/current_alerts',
            query: {language: 'en'}
          ).to_return Stub.json([])

          Stub.request(
            :pinboard, :get, '/topics',
            query: {item_id: item.id}
          ).to_return Stub.json([])
        end

        it 'sets the meta tags properly' do
          action
          expect(response.body).to _have_xpath '//title'
          expect(response.body).to _have_xpath "//meta[@property='og:title']"
          expect(response.body).to _have_xpath "//meta[@property='og:image']"
          expect(response.body).to _have_xpath "//meta[@property='og:type']"
          expect(response.body).to _have_xpath "//meta[@property='og:url']"
        end
      end

      context 'with a quiz' do
        render_views

        let(:course_state) { 'active' }
        let(:item) { create(:item, content_id: quiz_id, content_type: 'quiz', section:) }
        let(:quiz_id) { generate(:quiz_id) }

        before do
          Stub.service(:quiz, build(:'quiz:root'))

          Stub.request(
            :quiz, :get, "/quizzes/#{quiz_id}"
          ).to_return Stub.json(build(:'quiz:quiz', id: quiz_id))
          Stub.request(
            :quiz, :get, '/questions',
            query: hash_including(quiz_id:)
          ).to_return Stub.json(build_list(:'quiz:question', 2, quiz_id:))
        end

        context 'without an enrollment' do
          before do
            Stub.request(
              :course, :get, '/enrollments',
              query: {course_id: course.id, user_id:}
            ).to_return Stub.json([])
          end

          it 'shows a friendly error message' do
            action
            expect(response.body).to have_content 'Please enroll to see this quiz'
          end
        end
      end
    end
  end
end
