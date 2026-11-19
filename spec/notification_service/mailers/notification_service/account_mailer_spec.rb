# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationService::AccountMailer, type: :mailer do
  describe '#account_reactivation' do
    subject(:mail) { described_class.account_reactivation(user, login_url) }

    let(:login_url) { 'https://xikolo.de/sessions/new' }
    let(:user) { create(:'account_service/user') }

    it 'renders the headers correctly' do
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(%w[no-reply@xikolo.de])
      expect(mail.subject).to eq('Your Xikolo account has been reactivated')
    end

    it 'renders the body correctly' do
      expect(conv_str(mail.html_part)).to include('Your account has been reactivated.')
      expect(conv_str(mail.html_part)).to include(login_url)

      expect(conv_str(mail.text_part)).to include('Your account has been reactivated.')
      expect(conv_str(mail.text_part)).to include(login_url)
    end

    context 'for a German user' do
      let(:user) { create(:'account_service/user', language: 'de') }

      it 'has German subject and body' do
        expect(mail.subject).to eq('Ihr Xikolo Benutzerkonto wurde reaktiviert')

        expect(conv_str(mail.html_part)).to include('Ihr Benutzerkonto wurde reaktiviert.')
        expect(conv_str(mail.text_part)).to include('Ihr Benutzerkonto wurde reaktiviert.')
      end
    end
  end
end
