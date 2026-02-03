# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Progress', type: :request do
  subject(:show_progress) do
    get "/courses/#{course.course_code}/progress", headers:
  end

  let(:headers) { {} }
  let(:request_context_id) { course_resource['context_id'] }
  let(:course) { create(:course, title: 'My Awesome Course', records_released: true) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code,
      title: 'My Awesome Course',
      context_id: generate(:context_id))
  end
  let(:progresses) { build(:'course:progresses') }

  before do
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .and_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects the user' do
      show_progress
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end

  context 'for logged-in user' do
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }
    let(:user_id) { generate(:user_id) }
    let(:enrollments) { [] }
    let(:permissions) { [] }
    let(:features) { {} }
    let(:page) { Capybara.string(response.body) }

    before do
      stub_user_request(id: user_id, permissions:, features:)

      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, user_id:, learning_evaluation: true}
      ).and_return Stub.json(enrollments)
      Stub.request(
        :course, :get, '/progresses',
        query: {course_id: course.id, user_id:}
      ).and_return Stub.json(progresses)
      Stub.request(:course, :get, '/next_dates', query: hash_including({}))
        .to_return Stub.json([])
    end

    it 'redirects the user if not enrolled' do
      show_progress
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end

    context 'when the user is enrolled in the course' do
      let(:permissions) { %w[course.content.access.available] }
      let(:enrollments) do
        [build(:'course:enrollment', course_id: course.id, user_id:, certificates:)]
      end
      let(:certificates) do
        {
          record_of_achievement: false,
          confirmation_of_participation: false,
          certificate: false,
        }
      end

      before do
        Stub.request(:course, :get, "/courses/#{course.id}")
          .and_return Stub.json(course_resource)
      end

      it 'displays the course progress page' do
        show_progress
        expect(response.body).to include 'My learning progress'
      end
    end
  end
end
