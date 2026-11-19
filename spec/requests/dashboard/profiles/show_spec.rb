# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard: Profile: Show', type: :request do
  subject(:request) { get '/dashboard/profile' }

  let(:user_id) { generate(:user_id) }
  let(:email) { 'jon.doe@internet.org' }
  let(:user_resource) do
    attributes_for(:'account_service/user', id: user.id, email:)
      .merge(consents_url: "http://localhost:3000/account_service/users/#{user_id}/consents")
  end
  let(:user) { create(:'account_service/user', id: user_id) }

  before do
    sign_in(user:)

    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user_resource)
    Stub.request(:account, :get, "/users/#{user_id}/emails")
      .to_return Stub.json([attributes_for(:'account_service/email', user_id:, address: email)])
    Stub.request(:account, :get, "/users/#{user_id}/profile")
      .to_return Stub.json({user_id:, fields: []})
    Stub.request(:account, :get, "/authorizations?user=#{user_id}")
      .to_return Stub.json({})
    Stub.request(:account, :get, "/users/#{user_id}/consents")
      .to_return Stub.json([])
  end

  context 'with the profile feature flipper' do
    let(:features) { {'profile' => 'true'} }

    it 'can be accessed' do
      request
      expect(response).to have_http_status :ok
    end
  end

  context 'without the profile feature flipper' do
    before do
      AccountService::Feature.where(name: 'profile').delete_all
    end

    it 'cannot be accessed' do
      expect { request }.to raise_error(AbstractController::ActionNotFound)
    end
  end

  describe 'the guardian consent' do
    subject(:page) { request; Capybara.string(response.body) }

    let(:user) { create(:'account_service/user', id: user_id, born_at:, guardian_consent_at:) }
    let(:born_at) { 12.years.ago }
    let(:guardian_consent_at) { 1.day.ago }

    before do
      user.features.create(name: 'profile', value: 'true', context: AccountService::Context.root)
    end

    context 'when the user is underage and has confirmed it' do
      it 'is listed among the consents, as given and required' do
        expect(page).to have_text 'Disclaimer under 16 years old'
        expect(page).to have_text 'You have given this consent on'
        expect(page).to have_text 'Required'
        expect(page).to have_link 'privacy policy', href: '/pages/data-protection'
      end
    end

    context 'when the user is of age' do
      let(:born_at) { 20.years.ago }

      it 'is not listed, as only underage users ever hold one' do
        expect(page).to have_no_text 'Disclaimer under 16 years old'
      end
    end

    context 'without a birthdate' do
      let(:born_at) { nil }

      it 'is not listed' do
        expect(page).to have_no_text 'Disclaimer under 16 years old'
      end
    end

    context 'when the user is underage but has not confirmed it' do
      let(:guardian_consent_at) { nil }

      it 'is not listed' do
        expect(page).to have_no_text 'Disclaimer under 16 years old'
      end
    end
  end
end
