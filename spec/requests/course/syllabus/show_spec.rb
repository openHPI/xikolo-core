# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Course: Syllabus: Show', type: :request do
  subject(:show_syllabus) { get '/learn/my-course/overview' }

  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:course) { create(:'course_service/course', title: 'The Course', course_code: 'my-course') }
  let(:section) do
    create(:'course_service/section', course:, published: true,
      start_date: 1.day.ago, end_date: 1.day.from_now)
  end
  let(:video) do
    create(:'course_service/item', section:, title: 'The Video Item',
      content_type: 'Video::Video', open_mode: true, published: true)
  end
  let(:quiz) do
    create(:'course_service/item', section:, title: 'The Quiz Item',
      content_type: 'QuizService::Quiz', exercise_type: 'main', open_mode: true, published: true)
  end

  before do
    xi_config <<~YML
      open_mode:
        enabled: false
        default_value: false
    YML

    video
    quiz
  end

  shared_examples 'a syllabus' do
    before { show_syllabus }

    it 'responds with a syllabus page' do
      expect(response.body).to include('item-status')
      expect(response.body).to include('The Video Item')
      expect(response.body).to include('The Quiz Item')
    end

    it 'links to the quiz item' do
      expect(response.body).to include("href=\"/learn/my-course/items/#{UUID4.new(quiz.id).to_param}\"")
    end
  end

  shared_examples 'a syllabus in open_mode' do
    before { show_syllabus }

    it 'responds with a syllabus page' do
      expect(response.body).to include('item-status')
      expect(response.body).to include('The Video Item')
      expect(response.body).to include('The Quiz Item')
    end

    it 'does not link to the quiz item' do
      expect(response.body).not_to include("href=\"/learn/my-course/items/#{UUID4.new(quiz.id).to_param}\"")
    end
  end

  context 'as anonymous user' do
    let(:user_id) { 'anonymous' }

    it 'does not show the syllabus' do
      show_syllabus

      expect(response).to redirect_to '/learn/my-course'
    end
  end

  context 'as logged in user' do
    let(:permissions) { [] }
    let(:enrollments) { [] }

    before do
      sign_in(user:)
      role = create(:'account_service/role', permissions:)
      create(:'account_service/grant', principal: user, role:)

      Stub.request(
        :course, :get, '/enrollments',
        query: {user_id:, course_id: course['id']}
      ).to_return Stub.json(enrollments)
    end

    context 'without an enrollment for the current course' do
      it 'does not show a syllabus' do
        show_syllabus

        expect(response).to redirect_to '/learn/my-course'
      end
    end

    context 'with an enrollment for the current course' do
      let(:permissions) { ['course.content.access.available'] }
      let(:enrollments) { [{course_id: course['id'], user_id:}] }

      it_behaves_like 'a syllabus'
    end
  end

  context 'with open mode enabled' do
    before do
      xi_config <<~YML
        open_mode:
          enabled: true
          default: false
      YML

      Stub.request(
        :course, :get, '/items/current?',
        query: {course: course['id'], preview: false, user: user_id}
      ).to_return Stub.json([])

      Stub.request(
        :course, :get, '/items',
        query: {course_id: course['id'], open_mode: true}
      ).to_return Stub.json([video])
    end

    context 'as anonymous user' do
      let(:user_id) { 'anonymous' }

      it_behaves_like 'a syllabus in open_mode'
    end

    context 'as logged in user' do
      let(:enrollments) { [] }
      let(:authenticate) { true }

      before do
        sign_in(user:)

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json(enrollments)
      end

      context 'without an enrollment for the current course' do
        it_behaves_like 'a syllabus in open_mode'
      end

      context 'with an enrollment for the current course' do
        before do
          role = create(:'account_service/role', permissions: ['course.content.access.available'])
          create(:'account_service/grant', principal: user, role:)
        end

        let(:enrollments) { [{course_id: course['id'], user_id:}] }

        it_behaves_like 'a syllabus'
      end
    end
  end
end
