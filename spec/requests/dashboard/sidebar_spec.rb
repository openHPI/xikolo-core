# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Sidebar', type: :request do
  subject(:show_dashboard) { get '/dashboard', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:features) { {} }

  before do
    stub_user_request(id: user_id, features:)

    # Stubs for the sidebar content
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(user_id:, learning_evaluation: 'true')
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/courses',
      query: {promoted_for: user_id}
    ).to_return Stub.json([
      build(:'course:course', title: 'Promoted course 1'),
      build(:'course:course', title: 'Promoted course 2'),
    ])
    Stub.request(
      :course, :get, '/next_dates',
      query: {user_id:}
    ).to_return Stub.json([])
    Stub.request(
      :account, :post, '/tokens',
      body: hash_including(user_id:)
    ).to_return Stub.json({token: 'abc'})
  end

  context 'with enabled course recommendations' do
    let(:features) { {'dashboard.course_recommendations' => 'true'} }

    it 'renders the upcoming courses carousel' do
      show_dashboard
      expect(response).to have_http_status :ok
      expect(response.body).to include 'Course Recommendations'
      expect(response.body).to include 'Promoted course 1'
      expect(response.body).to include 'Promoted course 2'
    end
  end

  context 'with disabled course recommendations' do
    it 'does not render the upcoming courses carousel' do
      show_dashboard
      expect(response).to have_http_status :ok
      expect(response.body).not_to include 'Course Recommendations'
    end
  end

  context 'as anonymous user' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      show_dashboard
      expect(request).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
