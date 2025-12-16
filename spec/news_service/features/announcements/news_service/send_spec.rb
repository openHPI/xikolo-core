# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcements: Send email to all recipients', type: :feature do
  let(:announcement) { create(:'news_service/announcement', :with_url_in_content, recipients:) }

  let(:recipients) do
    %w[urn:x-xikolo:account:group:xikolo.active
       urn:x-xikolo:account:user:b4864a87-ee46-415d-9271-34b8766a40f2]
  end

  before do
    Stub.service(:account, build(:'account:root'))

    Stub.request(:account, :get, '/groups/xikolo.active')
      .to_return Stub.json({members_url: '/account_service/groups/xikolo.active/members'})
    Stub.request(:account, :get, '/groups/xikolo.active/members')
      .to_return Stub.json(
        [{
          id: 'b4864a87-ee46-415d-9271-34b8766a40f2',
          email: 'bob@example.org',
          language: 'en',
        }, {
          id: 'c2f2be7b-5304-4648-9b89-015a1627514b',
          email: 'alice@example.org',
          language: 'en',
        }]
      )

    Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2')
      .to_return Stub.json({
        id: 'b4864a87-ee46-415d-9271-34b8766a40f2',
        email: 'bob@example.org',
        language: 'en',
        emails_url: '/account_service/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails',
      })
    Stub.request(:account, :get, '/users/b4864a87-ee46-415d-9271-34b8766a40f2/emails')
      .to_return Stub.json([{id: SecureRandom.uuid}])

    Stub.request(:account, :get, '/users/c2f2be7b-5304-4648-9b89-015a1627514b')
      .to_return Stub.json({
        id: 'c2f2be7b-5304-4648-9b89-015a1627514b',
        email: 'alice@example.org',
        language: 'en',
        emails_url: '/account_service/users/c2f2be7b-5304-4648-9b89-015a1627514b/emails',
      })
    Stub.request(:account, :get, '/users/c2f2be7b-5304-4648-9b89-015a1627514b/emails')
      .to_return Stub.json([{id: SecureRandom.uuid}])
  end

  it 'sends an email to all disjunct users' do
    Sidekiq::Testing.inline! do
      NewsService::Message::Create.call(announcement)
    end

    html_body = ActionMailer::Base.deliveries.first.html_part.body

    expect(ActionMailer::Base.deliveries.count).to eq 2

    ActionMailer::Base.deliveries[0].tap do |mail|
      expect(mail.to).to eq %w[bob@example.org]
    end

    ActionMailer::Base.deliveries[1].tap do |mail|
      expect(mail.to).to eq %w[alice@example.org]
    end

    # URLs are linkified
    expect(html_body.raw_source).to include 'click on <a href='
  end
end
