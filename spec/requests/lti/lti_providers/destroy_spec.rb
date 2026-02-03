# frozen_string_literal: true

require 'spec_helper'

describe 'LTI Providers: Destroy', type: :request do
  subject(:destroy_lti_provider) { delete "/courses/#{course['course_code']}/lti_providers/#{provider.id}", headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:course) { build(:'course:course') }
  let(:provider) { create(:lti_provider, course_id: course['id']) }
  let(:permissions) { [] }

  before do
    stub_user_request(permissions:)
    Stub.request(
      :course, :get, "/courses/#{course['course_code']}"
    ).to_return Stub.json(
      course
    )
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])

    provider
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      expect(destroy_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end

  context 'with permissions' do
    let(:permissions) { %w[lti.provider.manage course.content.access] }

    it 'destroys the LTI provider' do
      expect { destroy_lti_provider }.to change(Lti::Provider, :count).from(1).to(0)
    end

    it 'redirects to the index page' do
      expect(destroy_lti_provider).to redirect_to course_lti_providers_path
    end

    it 'shows a success message' do
      destroy_lti_provider
      expect(flash[:success].first).to eq 'The LTI provider has successfully been deleted.'
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      expect(destroy_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end
end
