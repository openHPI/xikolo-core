# frozen_string_literal: true

require 'spec_helper'

describe 'LTI Providers: Create', type: :request do
  subject(:create_lti_provider) { post "/courses/#{course['course_code']}/lti_providers", params: {lti_provider: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:course) { build(:'course:course') }
  let(:permissions) { [] }
  let(:params) do
    {
      consumer_key: 'consumer',
      description: 'Hands-on programming',
      domain: 'https://www.example.com',
      name: 'A Provider',
      presentation_mode: 'window',
      privacy: 'anonymized',
      shared_secret: 'secret',
    }
  end

  before do
    stub_user_request(permissions:)
    Stub.service(:course, build(:'course:root'))
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
      expect(create_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end

  context 'with permissions' do
    let(:permissions) { %w[lti.provider.manage course.content.access] }

    it 'creates a new LTI provider' do
      expect { create_lti_provider }.to change(Lti::Provider, :count).from(0).to(1)
    end

    it 'redirects to index' do
      expect(create_lti_provider).to redirect_to course_lti_providers_path
    end

    it 'shows a success message' do
      create_lti_provider
      expect(flash[:success].first).to eq 'The LTI provider has successfully been created.'
    end

    context 'with missing attributes' do
      let(:params) do
        {
          name: 'Provider',
          description: 'description',
        }
      end

      it 'does not create a provider' do
        expect { create_lti_provider }.not_to change(Lti::Provider, :count)
      end

      it 'displays an error message' do
        create_lti_provider
        expect(flash[:error].first).to include 'The LTI provider has not been created.'
      end

      it 'renders the index action' do
        expect(create_lti_provider).to render_template :index
      end
    end

    context 'with an invalid attribute' do
      let(:params) { super().merge name: ' ' }

      it 'does not create a provider' do
        expect { create_lti_provider }.not_to change(Lti::Provider, :count)
      end

      it 'displays an error message' do
        create_lti_provider
        expect(flash[:error].first).to include 'The LTI provider has not been created.'
      end

      it 'renders the index action' do
        expect(create_lti_provider).to render_template :index
      end
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      expect(create_lti_provider).to redirect_to course_path(course['course_code'])
    end
  end
end
