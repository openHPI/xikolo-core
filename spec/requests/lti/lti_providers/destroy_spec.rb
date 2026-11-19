# frozen_string_literal: true

require 'spec_helper'

describe 'LTI Providers: Destroy', type: :request do
  subject(:destroy_lti_provider) { delete "/learn/#{course['course_code']}/lti_providers/#{provider.id}" }

  let(:course) { create(:'course_service/course') }
  let(:provider) { create(:lti_provider, course_id: course['id']) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }

  before do
    sign_in(user:) if authenticate

    Stub.request(
      :course, :get, "/courses/#{course['course_code']}"
    ).to_return Stub.json(
      course
    )
    provider
  end

  context 'without permissions' do
    it 'redirects to the homepage' do
      expect(destroy_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end

  context 'with permissions' do
    before do
      role = create(:'account_service/role', permissions: %w[lti.provider.manage course.content.access])
      create(:'account_service/grant', principal: user, role:)
    end

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
    let(:authenticate) { false }

    it 'redirects to the login page' do
      expect(destroy_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end
end
