# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationService::SendAccountReactivationEmailJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let(:user) { create(:'account_service/user') }
  let(:login_url) { 'https://xikolo.de/sessions/new' }

  let(:payload) do
    {
      user_id: user.id,
      url: login_url,
    }
  end

  context 'when the user has an email' do
    it 'sends the account reactivation email' do
      mailer = instance_double(ActionMailer::MessageDelivery)

      allow(NotificationService::AccountMailer)
        .to receive(:account_reactivation)
        .with(user, login_url)
        .and_return(mailer)

      expect(mailer).to receive(:deliver_now)

      perform_job
    end
  end

  context 'when the user does not exist' do
    let(:payload) { {user_id: SecureRandom.uuid, url: login_url} }

    it 'does not send an email' do
      expect(NotificationService::AccountMailer).not_to receive(:account_reactivation)

      expect { perform_job }.not_to raise_error
    end
  end
end
