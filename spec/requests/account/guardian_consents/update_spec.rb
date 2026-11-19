# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Guardian consents: Update', type: :request do
  subject(:update) { put '/account/guardian_consent', params: }

  let(:params) { {guardian_consent: 'true'} }
  let(:user) { create(:'account_service/user', completed_profile: true, born_at: 12.years.ago) }

  before { sign_in(user:) }

  it 'records when the consent was given' do
    update

    expect(user.reload.guardian_consent_at).to be_within(1.minute).of(Time.zone.now)
  end

  it 'sends the user on to their dashboard' do
    update

    expect(response).to redirect_to dashboard_url
  end

  it 'lifts the interrupt' do
    update
    get '/dashboard'

    expect(response).to have_http_status :ok
  end

  context 'when the checkbox was not ticked' do
    let(:params) { {} }

    it 'records nothing and sends the user back to the form' do
      update

      expect(user.reload.guardian_consent_at).to be_nil
      expect(response).to redirect_to account_guardian_consent_path
    end

    it 'keeps interrupting the user' do
      update
      get '/dashboard'

      expect(response).to redirect_to account_guardian_consent_path
    end
  end

  context 'when the consent was already given' do
    let(:user) do
      create(:'account_service/user', completed_profile: true, born_at: 12.years.ago,
        guardian_consent_at: 2.days.ago)
    end

    it 'can still be revisited' do
      get '/account/guardian_consent'

      expect(response).to have_http_status :ok
    end

    it 'keeps the timestamp of the first consent' do
      expect { update }.not_to change { user.reload.guardian_consent_at }
    end
  end

  context 'when the user is of age' do
    let(:user) { create(:'account_service/user', completed_profile: true, born_at: 30.years.ago) }

    it 'cannot open the page' do
      expect { get '/account/guardian_consent' }.to raise_error(Status::NotFound)
    end
  end

  context 'without a birthdate' do
    let(:user) { create(:'account_service/user', completed_profile: true, born_at: nil) }

    it 'cannot open the page' do
      expect { get '/account/guardian_consent' }.to raise_error(Status::NotFound)
    end
  end
end
