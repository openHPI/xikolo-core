# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::SendAnnouncementJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let(:news_id) { SecureRandom.uuid }

  let(:receiver_id) { generate(:user_id) }

  let(:stubbed_user_preferences) do
    {
      'news.announcement' => 'true',
    }
  end
  let(:stubbed_user_features) { {} }

  let(:payload) do
    {
      key: 'news.announcement',
      receiver_id: receiver_id,
      payload: {
        news_id: news_id,
        course_id: generate(:course_id),
        test: false,
      },
    }
  end

  before do
    Stub.request(
      :news,
      :get,
      "/news/#{news_id}?embed=translations"
    ).to_return Stub.json({
      id: news_id,
      language: 'en',
      text: 'Main text',
      translations: {
        'de' => {'text' => 'German text'},
      },
    })
    allow(I18n).to receive(:t).and_return('Subject')

    Stub.request(:account, :get, "/users/#{receiver_id}")
      .to_return Stub.json({
        id: receiver_id,
            email: 'test@email.com',
            archived: false,
            emails_url: "/account_service/users/#{receiver_id}/emails",
            features_url: "/account_service/users/#{receiver_id}/features",
            preferences_url: "/account_service/users/#{receiver_id}/preferences",
      })

    Stub.request(:account, :get, "/users/#{receiver_id}/preferences")
      .to_return Stub.json({properties: stubbed_user_preferences})

    Stub.request(:account, :get, "/users/#{receiver_id}/emails")
      .to_return Stub.json([
        {id: SecureRandom.uuid, address: 'test@email.com'},
      ])
    Stub.request(:account, :get, "/users/#{receiver_id}/features")
      .to_return Stub.json(stubbed_user_features)
  end

  it 'sends an announcement email' do
    expect { perform_job }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
  end

  it 'creates a MailLog entry' do
    expect { perform_job }
      .to change(NotificationService::MailLog, :count).by(1)
  end
end
