# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.notification.notify', type: :event do
  subject(:notify_event) { Msgr::TestPool.run count: 1 }

  let(:receiver_id) { generate(:user_id) }
  let(:stubbed_user_preferences) { {} }
  let(:stubbed_user_features) { {} }

  before do
    Stub.request(
      :account, :get, "/users/#{receiver_id}"
    ).to_return Stub.json({
      id: receiver_id,
      email: 'test@email.com',
      archived: false,
      emails_url: "/account_service/users/#{receiver_id}/emails",
      features_url: "/account_service/users/#{receiver_id}/features",
      preferences_url: "/account_service/users/#{receiver_id}/preferences",
    })
    Stub.request(
      :account, :get, "/users/#{receiver_id}/preferences"
    ).to_return Stub.json({properties: stubbed_user_preferences})
    Stub.request(
      :account, :get, "/users/#{receiver_id}/features"
    ).to_return Stub.json(stubbed_user_features)
    Stub.request(
      :account, :get, "/users/#{receiver_id}/emails"
    ).to_return Stub.json([
      {id: SecureRandom.uuid, address: 'test@email.com'},
    ])

    Msgr.client.start
    Msgr.publish(payload, to: 'xikolo.notification.notify')
  end

  describe 'a new global announcement' do
    let(:payload) do
      {
        key: 'news.announcement',
        receiver_id:,
        payload: {
          timestamp: DateTime.now.iso8601,
          subject: {'en' => 'English Announcement Title'},
          text: {'en' => 'some text'},
          test: false,
        },
      }
    end

    it 'sends an email' do
      expect { notify_event }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'creates a MailLog entry' do
      expect { notify_event }.to change(NotificationService::MailLog, :count).from(0).to(1)
    end

    describe 'the email' do
      subject(:email) { notify_event; ActionMailer::Base.deliveries.last }

      it 'contains disable links' do
        # The base URL
        expect(conv_str(email.text_part)).to include 'https://xikolo.de/notification_user_settings/disable'

        # The setting keys (global and type-specific)
        expect(conv_str(email.text_part)).to include 'key=global'
        expect(conv_str(email.text_part)).to include 'key=announcement'

        # The user's email address
        expect(conv_str(email.text_part)).to include 'test@email.com'
      end
    end
  end

  describe 'a new post in a forum thread' do
    let(:payload) do
      {
        key: 'pinboard.new_post',
        receiver_id:,
        payload: {
          timestamp: DateTime.now.iso8601,
          text: 'Long text with URLs http://google.com/search and https://xikolo.de/news',
          html: '<p>Long text with URLs <a href="http://google.com/search">http://google.com/search</a> and <a href="https://xikolo.de/news">https://xikolo.de/news</a></p>',
          username: 'TheoRetisch',
          user_name: 'TheoRetisch',
          course_name: 'A Course',
          link: '/questions/123',
        },
      }
    end

    it 'sends an email' do
      expect { notify_event }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    context 'with deleted user' do
      before do
        Stub.request(
          :account, :get, "/users/#{receiver_id}"
        ).to_return Stub.response(status: 404)
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with archived user' do
      before do
        Stub.request(
          :account, :get, "/users/#{receiver_id}"
        ).to_return Stub.json({
          id: receiver_id,
          email: 'test@email.com',
          archived: true,
          emails_url: "/users/#{receiver_id}/emails",
          features_url: "/users/#{receiver_id}/features",
          preferences_url: "/users/#{receiver_id}/preferences",
        })
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with user without email address' do
      before do
        Stub.request(
          :account, :get, "/users/#{receiver_id}"
        ).to_return Stub.json({
          id: receiver_id,
          email: nil,
          emails_url: "/users/#{receiver_id}/emails",
          features_url: "/users/#{receiver_id}/features",
          preferences_url: "/users/#{receiver_id}/preferences",
        })
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with notifications disabled globally' do
      let(:stubbed_user_preferences) do
        super().merge('notification.email.global' => 'false')
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with notifications disabled for pinboard mails' do
      # NOTE: The preference key for pinboard mails is different from the
      #       notification type key.
      let(:stubbed_user_preferences) do
        super().merge('notification.email.pinboard.new_answer' => 'false')
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with notifications explicitly enabled for pinboard mails' do
      let(:stubbed_user_preferences) do
        super().merge('notification.email.pinboard.new_answer' => 'true')
      end

      it 'sends an email' do
        expect { notify_event }.to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'with primary email suspended' do
      let(:stubbed_user_features) do
        super().merge('primary_email_suspended' => 1.minute.ago)
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    describe 'the email' do
      subject(:email) { notify_event; ActionMailer::Base.deliveries.last }

      context 'with tracking disabled' do
        before { Xikolo.config.track_mails = false }

        it 'does not change the URLs' do
          expect(conv_str(email.text_part)).to include 'http://google.com/search'
          expect(conv_str(email.html_part)).to include 'http://google.com/search'
          expect(conv_str(email.text_part)).to include 'https://xikolo.de/news'
          expect(conv_str(email.html_part)).to include 'https://xikolo.de/news'
        end
      end

      context 'with tracking enabled' do
        before { Xikolo.config.track_mails = true }

        shared_examples 'external URLs' do
          it 'are routed through /go' do
            expect(conv_str(email.text_part)).to include '/go/link?url=http%3A%2F%2Fgoogle.com%2Fsearch'
            expect(conv_str(email.html_part)).to include '/go/link?url=http%3A%2F%2Fgoogle.com%2Fsearch'
            expect(conv_str(email.text_part)).not_to include 'http://google.com/search'
            expect(conv_str(email.html_part)).not_to include 'href="http://google.com/search"'
          end
        end

        shared_examples 'unsubscribe links' do
          it 'are included in the email' do
            expect(conv_str(email.text_part)).to match %r{https://xikolo.de/notification_user_settings/disable\?\S+&key=pinboard&}
            expect(conv_str(email.html_part)).to match %r{https://xikolo.de/notification_user_settings/disable\?\S+&amp;key=pinboard&amp;}
          end
        end

        it_behaves_like 'external URLs'

        it 'appends tracking parameters to internal URLs retaining the protocol' do
          expect(conv_str(email.text_part)).to include 'https://xikolo.de/news?tracking_'
          expect(conv_str(email.html_part)).to include 'https://xikolo.de/news?tracking_'
        end

        it_behaves_like 'unsubscribe links'

        context 'with http protocol for internal URLs' do
          let(:payload) do
            super().merge(
              payload: {
                timestamp: DateTime.now.iso8601,
                text: 'Long text with URLs http://google.com/search and http://xikolo.de/news',
                html: '<p>Long text with URLs <a href="http://google.com/search">http://google.com/search</a> and <a href="http://xikolo.de/news">http://xikolo.de/news</a></p>',
                username: 'TheoRetisch',
                user_name: 'TheoRetisch',
                course_name: 'A Course',
                link: '/questions/123',
              }
            )
          end

          it_behaves_like 'external URLs'

          it 'appends tracking parameters to internal URLs retaining the protocol' do
            expect(conv_str(email.text_part)).to include 'http://xikolo.de/news?tracking_'
            expect(conv_str(email.html_part)).to include 'http://xikolo.de/news?tracking_'
          end

          it_behaves_like 'unsubscribe links'
        end
      end
    end
  end

  describe 'a blocked post in a forum' do
    let(:payload) do
      {
        key: 'pinboard.blocked_item',
        receiver_id:,
        payload: {
          item_url: 'https://xikolo.de/forum/url/to/post/123',
        },
      }
    end

    it 'sends an email' do
      expect { notify_event }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    describe 'the email' do
      subject(:email) { notify_event; ActionMailer::Base.deliveries.last }

      it 'asks for review and links the post' do
        expect(email.subject).to eq 'Please review blocked pinboard item'
        expect(conv_str(email.text_part)).to include 'an item was automatically blocked. Please review!'
        expect(conv_str(email.html_part)).to include 'an item was automatically blocked. Please review!'
        expect(conv_str(email.text_part)).to include 'https://xikolo.de/forum/url/to/post/123'
        expect(conv_str(email.html_part)).to include 'https://xikolo.de/forum/url/to/post/123'
      end
    end

    context 'with deleted user' do
      before do
        Stub.request(
          :account, :get, "/users/#{receiver_id}"
        ).to_return Stub.response(status: 404)
      end

      it 'does not send an email' do
        expect { notify_event }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
