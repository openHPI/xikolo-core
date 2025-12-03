# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewsService::AnnouncementMailer, type: :mailer do
  describe '(email)' do
    subject(:mail) { described_class.call(message, user) }

    let(:message) { create(:'news_service/message') }
    let(:user) do
      {id: user_id, email: 'to@example.org', language: 'en'}.stringify_keys
    end
    let(:user_id) { SecureRandom.uuid }

    before do
      Stub.service(:account, build(:'account:root'))
      Stub.request(:account, :get, "/users/#{user_id}")
        .to_return Stub.json({
          id: user_id,
          emails_url: "/account_service/users/#{user_id}/emails",
        })
      Stub.request(:account, :get, "/users/#{user_id}/emails")
        .to_return Stub.json([{id: SecureRandom.uuid}])
    end

    it 'renders the headers correctly' do
      expect(mail.to).to eq(%w[to@example.org])
      expect(mail.from).to eq(%w[no-reply@xikolo.de])
      expect(mail.subject).to eq('English subject')
      expect(mail.header['List-Unsubscribe'].value).to include(
        'https://xikolo.de/notification_user_settings/disable?' \
        'email=to%40example.org',
        'key=announcement'
      )
    end

    it 'renders the body correctly' do
      expect(mail.body.encoded).to include('Oh, you gonna like my news...')
    end

    it 'surrounds the message body with the text direction div' do
      expect(mail.body.encoded).to include('<div dir=3D"auto">')
    end

    it 'attributes the headline with the text direction' do
      expect(mail.body.encoded).to include('<p class=3D"template-label text-right" dir=3D"auto"')
    end

    describe '(footer)' do
      subject(:mail) do
        described_class.call(message, user)
        ActionMailer::Base.deliveries.last
      end

      it 'contains disable links' do
        expect(mail.body.encoded).to include(
          'https://xikolo.de/notification_user_settings/disable',
          'to%40example.org',
          'key=global',
          'key=announcement'
        )
      end
    end
  end
end
