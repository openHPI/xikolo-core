# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Course: Syllabus: Show', type: :request do
  subject(:show_syllabus) { get '/courses/my-course/overview', headers: }

  let(:user_id) { generate(:user_id) }
  let(:course) { build(:'course:course', title: 'The Course') }
  let(:section) { build(:'course:section', course:) }
  let(:video) { build(:'course:item', :video, section:, title: 'The Video Item', open_mode: true) }
  let(:quiz) { build(:'course:item', :quiz, section:, title: 'The Quiz Item', open_mode: true) }
  let(:progresses) do
    [
      {
        resource_id: section['id'],
        kind: 'section',
        visits: {
          total: 1,
          user: 0,
          percentage: 0,
        },
        available: true,
        items: [video, quiz],
      },
      {
        resource_id: course['id'],
        kind: 'course',
      },
    ]
  end
  let(:headers) { {} }

  before do
    Stub.request(:course, :get, '/courses/my-course')
      .to_return Stub.json(course)

    Stub.request(:course, :get, "/items/#{video['id']}")
      .to_return Stub.json(video)
  end

  shared_examples 'a syllabus' do
    before { show_syllabus }

    it 'responds with a syllabus page' do
      expect(response.body).to include('item-status')
      expect(response.body).to include('The Video Item')
      expect(response.body).to include('The Quiz Item')
    end

    it 'links to the quiz item' do
      expect(response.body).to include("href=\"/courses/my-course/items/#{UUID4.new(quiz['id']).to_param}\"")
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
      expect(response.body).not_to include("href=\"/courses/my-course/items/#{UUID4.new(quiz['id']).to_param}\"")
    end
  end

  context 'as anonymous user' do
    let(:user_id) { 'anonymous' }

    it 'does not show the syllabus' do
      show_syllabus

      expect(response).to redirect_to '/courses/my-course'
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { [] }
    let(:enrollments) { [] }

    before do
      stub_user_request(id: user_id, permissions:)

      Stub.request(
        :course, :get, '/enrollments',
        query: {user_id:, course_id: course['id']}
      ).to_return Stub.json(enrollments)
    end

    context 'without an enrollment for the current course' do
      it 'does not show a syllabus' do
        show_syllabus

        expect(response).to redirect_to '/courses/my-course'
      end
    end

    context 'with an enrollment for the current course' do
      let(:permissions) { ['course.content.access.available'] }
      let(:enrollments) { [{course_id: course['id'], user_id:}] }

      before do
        Stub.request(
          :course, :get, '/sections',
          query: {course_id: course['id']}
        ).to_return Stub.json([section])

        Stub.request(
          :course, :get, '/progresses',
          query: {course_id: course['id'], user_id:}
        ).to_return Stub.json(progresses)
      end

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
        :course, :get, '/sections',
        query: {course_id: course['id']}
      ).to_return Stub.json([section])

      Stub.request(
        :course, :get, '/progresses',
        query: {course_id: course['id'], user_id:}
      ).to_return Stub.json(progresses)

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
      let(:anonymous_session) do
        super().merge(features: {'open_mode' => 'true'})
      end

      it_behaves_like 'a syllabus in open_mode'
    end

    context 'as logged in user' do
      let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
      let(:permissions) { [] }
      let(:enrollments) { [] }
      let(:logged_in_session) do
        super().merge(features: {'open_mode' => 'true'})
      end

      before do
        stub_user_request(id: user_id, permissions:, features: {'open_mode' => 'true'})

        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:, course_id: course['id']}
        ).to_return Stub.json(enrollments)
      end

      context 'without an enrollment for the current course' do
        it_behaves_like 'a syllabus in open_mode'
      end

      context 'with an enrollment for the current course' do
        let(:permissions) { ['course.content.access.available'] }
        let(:enrollments) { [{course_id: course['id'], user_id:}] }

        it_behaves_like 'a syllabus'
      end
    end
  end
end
