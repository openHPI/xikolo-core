# frozen_string_literal: true

require 'spec_helper'

describe LtiProvidersController, type: :controller do
  let(:course) { create(:course) }
  let(:user_id) { SecureRandom.uuid }
  let(:request_context_id) { course_context_id }
  let(:permissions) { ['lti.provider.manage', 'course.content.access'] }
  let(:provider_params) { {course_id: course.id, name: 'Provider'} }

  before do
    Stub.request(
      :course, :get, "/courses/#{course.id}"
    ).to_return Stub.json({
      id: course.id,
      context_id: course_context_id,
    })
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([])

    stub_user id: user_id, permissions:
  end

  describe 'GET #index' do
    subject(:get_index) do
      get :index, params: {course_id: course.id}
    end

    before { get_index }

    it 'responds with 200 Ok' do
      expect(controller.status).to eq(200)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:index)
    end
  end

  describe 'POST #create' do
    subject(:create_provider) do
      post :create,
        params: {
          course_id: course.id,
          lti_provider: provider_params,
        }
    end

    context 'with missing params' do
      it 'does not create the LTI provider' do
        expect { create_provider }.not_to change(Lti::Provider, :count)
      end

      it 're-renders the form' do
        expect(create_provider).to render_template :index
      end
    end

    context 'with invalid params' do
      let(:provider_params) { super().merge(name: '') }

      it 'does not create the LTI provider' do
        expect { create_provider }.not_to change(Lti::Provider, :count)
      end

      it 're-renders the form' do
        expect(create_provider).to render_template :index
      end
    end

    context 'with valid params and with permissions to change privacy but without setting it' do
      let(:permissions) { super().push('lti.provider.edit_privacy_mode') }

      let(:provider_params) do
        super().merge(
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret'
        )
      end

      it 'creates the LTI provider' do
        expect { create_provider }.to change(Lti::Provider, :count).from(0).to(1)
      end

      it 'redirects to the LTI providers page' do
        expect(create_provider).to redirect_to course_lti_providers_path
      end

      it 'has a default privacy of "anonymized"' do
        create_provider
        expect(Lti::Provider.last.privacy).to eq('anonymized')
      end
    end

    context 'with privacy params but without permission to change it' do
      let(:provider_params) do
        super().merge(
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret',
          privacy: 'unprotected'
        )
      end

      it 'ignores the privacy setting' do
        expect { create_provider }.to change(Lti::Provider, :count).from(0).to(1)
        expect(Lti::Provider.last.privacy).to eq('anonymized')
      end
    end

    context 'with privacy params and with edit permission' do
      let(:permissions) { super().push('lti.provider.edit_privacy_mode') }

      let(:provider_params) do
        super().merge(
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret',
          privacy: 'unprotected'
        )
      end

      it 'creates the provider as requested' do
        expect { create_provider }.to change(Lti::Provider, :count).from(0).to(1)
        expect(Lti::Provider.last.privacy).to eq('unprotected')
      end
    end
  end

  describe 'PUT #update' do
    subject(:update_provider) do
      put :update, params: {
        course_id: course.id,
        id: provider.id,
        lti_provider: provider_params,
      }
    end

    let(:provider) { create(:lti_provider, :anonymized, course_id: course.id) }

    context 'with invalid params' do
      let(:provider_params) { super().merge(name: '') }

      it 'does not update the LTI provider' do
        expect { update_provider }.not_to change { provider.reload.name }.from('Provider')
      end

      it 'redirects to index' do
        expect(update_provider).to redirect_to course_lti_providers_path
      end
    end

    context 'with valid params' do
      let(:provider_params) do
        super().merge(
          name: 'An Updated Provider',
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret'
        )
      end

      it 'updates the LTI provider' do
        expect { update_provider }.to change { provider.reload.name }.from('Provider').to('An Updated Provider')
      end

      it 'redirects to the index page' do
        expect(update_provider).to redirect_to course_lti_providers_path
      end
    end

    context 'with privacy params but without permission to change it' do
      let(:provider_params) do
        super().merge(
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret',
          privacy: 'unprotected'
        )
      end

      it 'ignores the privacy setting' do
        expect { update_provider }.not_to change { provider.reload.privacy }.from('anonymized')
      end
    end

    context 'with privacy params and with edit permission' do
      let(:permissions) { ['lti.provider.manage', 'course.content.access', 'lti.provider.edit_privacy_mode'] }

      let(:provider_params) do
        super().merge(
          domain: 'https://tools.example.com',
          consumer_key: 'consumer_key',
          shared_secret: 'shared_secret',
          privacy: 'unprotected'
        )
      end

      it 'updates the provider as requested' do
        expect { update_provider }.to change { provider.reload.privacy }.from('anonymized').to('unprotected')
      end
    end
  end

  describe 'DELETE #destroy' do
    subject(:destroy_provider) do
      delete :destroy, params: {course_id: course.id, id: provider.id}
    end

    let!(:provider) { create(:lti_provider, course_id: course.id) }

    it 'destroys the LTI provider' do
      expect { destroy_provider }.to change(Lti::Provider, :count).from(1).to(0)
    end

    it 'redirects to the index page' do
      expect(destroy_provider).to redirect_to course_lti_providers_path
    end
  end
end
