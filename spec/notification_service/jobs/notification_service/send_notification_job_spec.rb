# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::SendNotificationJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let(:receiver_id) { generate(:user_id) }
  let(:stubbed_user_preferences) { {} }
  let(:stubbed_user_features) { {} }

  before do
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

    Stub.request(:account, :get, "/users/#{receiver_id}/features")
      .to_return Stub.json(stubbed_user_features)

    Stub.request(:account, :get, "/users/#{receiver_id}/emails")
      .to_return Stub.json([
        {id: SecureRandom.uuid, address: 'test@email.com'},
      ])
  end

  describe 'a new post in a forum thread' do
    let(:payload) do
      {
        key: 'pinboard.new_post',
        receiver_id: receiver_id,
        payload: {
          timestamp: DateTime.now.iso8601,
          text: 'Long text with URLs http://google.com/search',
          html: '<p>Long text with URLs <a href="http://google.com/search">http://google.com/search</a></p>',
          username: 'TheoRetisch',
          user_name: 'TheoRetisch',
          course_name: 'A Course',
          link: '/questions/123',
        },
      }
    end

    it 'sends an email' do
      expect { perform_job }
        .to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    context 'with deleted user' do
      before do
        Stub.request(:account, :get, "/users/#{receiver_id}")
          .to_return Stub.response(status: 404)
      end

      it 'does not send an email' do
        expect { perform_job }
          .not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
