# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcement: Messages: Create', type: :request do
  subject(:resource) { announcement_resource.rel(:messages).post(payload).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:announcement_resource) { service.rel(:announcement).get({id: announcement.id}).value! }
  let(:announcement) { create(:announcement) }
  let(:payload) { {} }

  context 'without attributes' do
    it 'responds with 400 Bad Request' do
      expect { resource }.to raise_error(Restify::BadRequest)
    end
  end

  describe 'trigger test email' do
    let(:payload) do
      {creator_id: generate(:user_id), test: true, recipients: [user], consents: []}
    end
    let(:user) { build(:'recipient:user', id: 'b4864a87-ee46-415d-9271-34b8766a40f2') }

    before do
      Stub.service(:account, build(:'account:root'))

      Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2')
        .to_return Stub.json({
          id: 'b4864a87-ee46-415d-9271-34b8766a40f2',
          email: 'bob@example.org',
          language: 'en',
          emails_url: '/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails',
          groups_url: '/users/b4864a87-ee46-415d-9271-34b8766a40f2/groups',
        })
      Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails')
        .to_return Stub.json([{id: generate(:uuid)}])
    end

    it 'persists a message record' do
      Sidekiq::Testing.inline! { resource }

      expect(announcement.messages.count).to eq 1
      expect(announcement.messages.first.status).to eq 'sending'
    end

    it 'sends an email to the specified recipient' do
      Sidekiq::Testing.inline! { resource }

      mails = ActionMailer::Base.deliveries
      expect(mails.count).to eq 1
      expect(mails.last.to).to eq %w[bob@example.org]
      expect(mails.last.body.encoded).to include 'This is a test message, only you received this!'
    end

    context 'with consent filter' do
      let(:payload) { super().merge(consents: %w[treatment.consent]) }
      let(:user_groups) { [] }

      before do
        Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2/groups')
          .to_return Stub.json(user_groups)
      end

      context 'and the user has consented' do
        let(:user_groups) { [{name: 'treatment.consent'}] }

        it 'persists a message record' do
          Sidekiq::Testing.inline! { resource }

          expect(announcement.messages.count).to eq 1
          expect(announcement.messages.first.status).to eq 'sending'
        end

        it 'sends an email to the specified recipient' do
          Sidekiq::Testing.inline! { resource }

          mails = ActionMailer::Base.deliveries
          expect(mails.count).to eq 1
          expect(mails.last.to).to eq %w[bob@example.org]
          expect(mails.last.body.encoded).to include 'This is a test message, only you received this!'
        end
      end

      context 'and the user has not consented' do
        it 'persists a message record' do
          Sidekiq::Testing.inline! { resource }

          expect(announcement.messages.count).to eq 1
          expect(announcement.messages.first.status).to eq 'sending'
        end

        it 'does not send an email to the specified recipient' do
          Sidekiq::Testing.inline! { resource }

          mails = ActionMailer::Base.deliveries
          expect(mails.count).to be_zero
        end
      end
    end
  end

  describe 'trigger a real message' do
    let(:payload) { {creator_id: generate(:user_id), recipients: [group], consents: []} }
    let(:group) { build(:'recipient:group', id: 'xikolo.active') }

    before do
      Stub.service(:account, build(:'account:root'))

      Stub.request(:account, :get, '/groups/xikolo.active')
        .to_return Stub.json({members_url: '/groups/xikolo.active/members'})
      Stub.request(:account, :get, '/groups/xikolo.active/members')
        .to_return Stub.json(
          [
            {
              id: 'b4864a87-ee46-415d-9271-34b8766a40f2',
              email: 'bob@example.org',
              language: 'en',
            },
            {
              id: 'c2f2be7b-5304-4648-9b89-015a1627514b',
              email: 'alice@example.org',
              language: 'en',
            },
          ]
        )

      Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2')
        .to_return Stub.json({
          id: 'b4864a87-ee46-415d-9271-34b8766a40f2',
          email: 'bob@example.org',
          language: 'en',
          emails_url: '/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails',
        })
      Stub.request(:account, :get, '/users/c2f2be7b-5304-4648-9b89-015a1627514b')
        .to_return Stub.json({
          id: 'c2f2be7b-5304-4648-9b89-015a1627514b',
          email: 'alice@example.org',
          language: 'en',
          emails_url: '/users/c2f2be7b-5304-4648-9b89-015a1627514b/emails',
        })
      Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails')
        .to_return Stub.json([{id: generate(:uuid)}])
      Stub.request(:account, :get, '/users/c2f2be7b-5304-4648-9b89-015a1627514b/emails')
        .to_return Stub.json([{id: generate(:uuid)}])
    end

    it 'persists a message record' do
      Sidekiq::Testing.inline! { resource }

      expect(announcement.messages.count).to eq 1
      expect(announcement.messages.first.status).to eq 'sending'
    end

    it 'sends an email to all recipients' do
      Sidekiq::Testing.inline! { resource }

      mails = ActionMailer::Base.deliveries
      expect(mails.count).to eq 2
      expect(mails.last.to).to eq %w[alice@example.org]
      expect(mails.last.body.encoded).not_to include 'This is a test message, only you received this!'
    end

    context 'with consent filter' do
      let(:payload) { super().merge(consents: %w[treatment.consent]) }
      let(:consented_users) { [] }

      before do
        Stub.request(:account, :get, '/groups/treatment.consent')
          .to_return Stub.json({memberships_url: '/groups/treatment.consent/memberships'})
        Stub.request(
          :account, :get, '/groups/treatment.consent/memberships',
          query: {per_page: 10_000}
        ).to_return Stub.json(consented_users)
      end

      context 'and some users have consented' do
        let(:consented_users) { [{user: 'b4864a87-ee46-415d-9271-34b8766a40f2'}] }

        it 'persists a message record' do
          Sidekiq::Testing.inline! { resource }

          expect(announcement.messages.count).to eq 1
          expect(announcement.messages.first.status).to eq 'sending'
        end

        it 'sends an email to recipients who consented' do
          Sidekiq::Testing.inline! { resource }

          mails = ActionMailer::Base.deliveries
          expect(mails.count).to eq 1
          expect(mails.last.to).to eq %w[bob@example.org]
          expect(mails.last.body.encoded).not_to include 'This is a test message, only you received this!'
        end
      end

      context 'and the recipients have not consented' do
        it 'persists a message record' do
          Sidekiq::Testing.inline! { resource }

          expect(announcement.messages.count).to eq 1
          expect(announcement.messages.first.status).to eq 'sending'
        end

        it 'does not send an email' do
          Sidekiq::Testing.inline! { resource }

          mails = ActionMailer::Base.deliveries
          expect(mails.count).to be_zero
        end
      end
    end
  end
end
