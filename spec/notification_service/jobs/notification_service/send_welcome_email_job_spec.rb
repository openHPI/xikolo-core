# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationService::SendWelcomeEmailJob, type: :job do
  subject(:perform_job) do
    described_class.perform_now(user_id, confirmation_url)
  end

  let(:user_id) { 'c088d006-8886-4b3c-a6ac-d45f168abc5b' }
  let(:confirmation_url) { 'https://xikolo.de/welcome_email' }

  let(:user_response) do
    Stub.json({
      id: user_id,
      display_name: 'John Smith',
      email: 'john@example.de',
      language: 'en',
      features_url: "/account_service/users/#{user_id}/features",
    })
  end

  before do
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return user_response
  end

  context 'when the user has an email' do
    context 'when mandatory profile fields are completed' do
      before do
        Stub.request(
          :account, :get, "/users/#{user_id}/features"
        ).to_return Stub.json(
          {'account.profile.mandatory_completed': 't'}
        )
      end

      it 'sends the welcome email with mandatory_fields=true' do
        mailer = instance_double(ActionMailer::MessageDelivery)

        allow(NotificationService::AccountMailer)
          .to receive(:welcome_email)
          .with(hash_including('email' => 'john@example.de'), true, confirmation_url)
          .and_return(mailer)

        expect(mailer).to receive(:deliver_now)

        perform_job
      end
    end

    context 'when mandatory profile fields are NOT completed' do
      before do
        Stub.request(
          :account, :get, "/users/#{user_id}/features"
        ).to_return Stub.json({})
      end

      it 'sends the welcome email with mandatory_fields=false' do
        mailer = instance_double(ActionMailer::MessageDelivery)

        allow(NotificationService::AccountMailer)
          .to receive(:welcome_email)
          .with(hash_including('email' => 'john@example.de'), false, confirmation_url)
          .and_return(mailer)

        expect(mailer).to receive(:deliver_now)

        perform_job
      end
    end
  end

  context 'when the user has no email' do
    let(:user_response) do
      Stub.json({
        id: user_id,
        email: nil,
        features_url: "/account_service/users/#{user_id}/features",
      })
    end

    it 'does not send an email' do
      expect(NotificationService::AccountMailer).not_to receive(:welcome_email)
      perform_job
    end
  end

  context 'when the user does not exist' do
    let(:user_response) { Stub.response(status: 404) }

    it 'does not send an email' do
      expect(NotificationService::AccountMailer).not_to receive(:welcome_email)

      expect do
        perform_job
      end.not_to raise_error
    end
  end
end
