# frozen_string_literal: true

require 'spec_helper'

describe 'LTI Providers: Update', type: :request do
  subject(:update_lti_provider) { patch "/courses/#{course['course_code']}/lti_providers/#{provider.id}", params: {lti_provider: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:course) { build(:'course:course') }
  let(:provider) { create(:lti_provider, course_id: course['id']) }
  let(:permissions) { [] }
  let(:params) { {} }

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
  end

  context 'without permissions' do
    it 'redirects to the homepage' do
      expect(update_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end

  context 'with permissions' do
    let(:permissions) { %w[lti.provider.manage course.content.access] }

    context 'with valid attributes' do
      let(:params) { super().merge(name: 'Updated Provider') }

      it 'updates the LTI provider' do
        expect { update_lti_provider }.to change { provider.reload.name }
          .from('Provider')
          .to('Updated Provider')
      end

      it 'redirects to index' do
        expect(update_lti_provider).to redirect_to course_lti_providers_path
      end

      it 'shows a success message' do
        update_lti_provider
        expect(flash[:success].first).to eq 'The LTI provider has successfully been saved.'
      end
    end

    context 'with an invalid attribute' do
      let(:params) { {name: ' '} }

      it 'does not update the provider' do
        expect { update_lti_provider }.not_to change(provider, :name)
      end

      it 'displays an error message' do
        update_lti_provider
        expect(flash[:error].first).to eq 'The LTI provider has not been saved.'
      end

      it 'renders the index action' do
        expect(update_lti_provider).to redirect_to course_lti_providers_path
      end
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the course page' do
      expect(update_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end
end
