# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::SendPasswordResetEmailJob, type: :job do
  let(:user_id) { 'c088d006-8886-4b3c-a6ac-d45f168abc5b' }
  let(:token) { 'abc' }
  let(:password_reset_url) { 'https://xikolo.de/reset_password' }

  let(:payload) do
    {
      user_id: user_id,
      token: token,
      url: password_reset_url,
    }
  end

  before do
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      id: user_id,
      display_name: 'John Smith',
      email: 'john@example.de',
      language: 'en',
    })

    Stub.request(
      :account, :get, "/password_resets/#{token}"
    ).to_return Stub.json({
      token: token,
      user_id: user_id,
    })
  end

  describe '#perform' do
    it 'sends a password reset mail' do
      described_class.perform_now(payload)

      expect(mail).to be_a(Mail::Message)
      expect(mail.to).to include('john@example.de')
      expect(mail.from).to eql(['no-reply@xikolo.de'])

      expect(conv_str(mail.html_part)).to be_present
      expect(conv_str(mail.html_part)).to include(password_reset_url)

      expect(conv_str(mail.text_part)).to be_present
      expect(conv_str(mail.text_part)).to include(password_reset_url)
    end

    it 'ignores resets for deleted users' do
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
        display_name: 'Deleted User',
        email: nil,
        language: 'en',
      })

      described_class.perform_now(payload)

      expect(mail).to be_nil
    end

    context 'localization' do
      context 'for a German user' do
        before do
          Stub.request(
            :account, :get, "/users/#{user_id}"
          ).to_return Stub.json({
            id: user_id,
            display_name: 'John Smith',
            email: 'john@example.de',
            language: 'de',
          })
        end

        it 'has German text' do
          described_class.perform_now(payload)

          expect(mail.subject)
            .to eq('Passwort zurücksetzen für Ihr Xikolo Benutzerkonto')

          expect(conv_str(mail.html_part))
            .to include('Klicken Sie den untenstehenden Button, um das Passwort nun zurückzusetzen.')

          expect(conv_str(mail.text_part))
            .to include('Klicken Sie den untenstehenden Button, um das Passwort nun zurückzusetzen.')
        end
      end
    end
  end
end
