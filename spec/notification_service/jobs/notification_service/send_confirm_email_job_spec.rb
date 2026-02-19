# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::SendConfirmEmailJob, type: :job do
  let(:confirm_email_url) { 'https://xikolo.de/confirm_email' }
  let(:user_id) { 'c088d006-8886-4b3c-a6ac-d45f168abc5b' }
  let(:email_id) { '7dbf9da5-f3de-4b83-b5af-299d3fbf9e11' }
  let(:user_language) { 'en' }

  let(:payload) do
    {
      id: email_id,
      url: confirm_email_url,
      user_id: user_id,
    }
  end

  before do
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      id: user_id,
      display_name: 'John Smith',
      email: 'john@example.de',
      language: user_language,
      email_url: "/account_service/users/#{user_id}/emails/{id}",
    })

    Stub.request(
      :account, :get, "/users/#{user_id}/emails/#{email_id}"
    ).to_return Stub.json({
      id: email_id,
      user_id: user_id,
      address: 'john@theuniverse.com',
      primary: true,
      confirmed: false,
    })
  end

  describe '#perform' do
    it 'sends an address confirmation mail' do
      described_class.perform_now(payload)

      expect(mail).to be_a(Mail::Message)
      expect(mail.to).to include('john@theuniverse.com')
      expect(mail.from).to eql(['no-reply@xikolo.de'])

      expect(conv_str(mail.html_part)).to be_present
      expect(conv_str(mail.html_part)).to include(confirm_email_url)

      expect(conv_str(mail.text_part)).to be_present
      expect(conv_str(mail.text_part)).to include(confirm_email_url)
    end

    context 'localization' do
      context 'for a German user' do
        let(:user_language) { 'de' }

        it 'has German text' do
          described_class.perform_now(payload)

          expect(mail.subject).to eq('Bitte Bestätigen Sie Ihre E-Mail')

          expect(conv_str(mail.html_part)).to include(
            'Sie bekommen diese E-Mail, da Sie eine neue E-Mail-Adresse zu Ihrem Konto bei Xikolo hinzugefügt haben.'
          )

          expect(conv_str(mail.text_part)).to include(
            'Sie bekommen diese E-Mail, da Sie eine neue E-Mail-Adresse zu Ihrem Konto bei Xikolo hinzugefügt haben.'
          )
        end
      end
    end
  end
end
