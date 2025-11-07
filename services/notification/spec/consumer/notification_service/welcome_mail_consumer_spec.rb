# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::WelcomeMailConsumer, type: :consumer do
  let(:consumer) { NotificationService::WelcomeMailConsumer.new }
  let(:user_id) { '81187fa1-6cfd-4b90-a547-b546e24258b7' }
  let(:course_id) { '11187fa1-6cfd-4b90-a547-b546e24258b7' }
  let(:user_data) do
    {
      name: 'John Smith',
      email: 'john.smith@example.org',
      language: 'de',
    }
  end

  let(:payload) { {user_id:, course_id:} }
  let(:params) { {user_id:, course_id:} }
  let(:preferences) do
    {
      'notification.email.test.key' => 'true',
        'notification.email.test.key2' => 'false',
    }
  end
  let(:mail_stub) { instance_double(ActionMailer::MessageDelivery) }

  before do
    allow(consumer).to receive(:payload)
      .and_return params

    allow(NotificationService::CourseWelcomeMailer).to receive(:welcome_mail).and_return(mail_stub)
    allow(mail_stub).to receive(:deliver_now!)
  end

  describe '#notify' do
    before do
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return user_response
      Stub.request(
        :account, :get, "/users/#{user_id}/preferences"
      ).to_return Stub.json({properties: preferences})
      Stub.request(
        :account, :get, "/users/#{user_id}/features"
      ).to_return Stub.json({})

      Stub.request(
        :course, :get, "/courses/#{course_id}"
      ).to_return course_response
    end

    let(:user_response) do
      Stub.json({
        **user_data,
        id: user_id,
        features_url: "/users/#{user_id}/features",
        preferences_url: "/users/#{user_id}/preferences",
      })
    end

    let(:course_response) do
      Stub.json({
        id: course_id,
        title: 'some title',
        welcome_mail: 'welcome to this course',
      })
    end

    context 'with deleted user' do
      let(:user_response) { Stub.response(status: 404) }

      it 'drops the notification' do
        expect(consumer.notify).to be false
      end
    end

    context 'with archived receiver' do
      let(:user_data) { super().merge archived: true }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        consumer.notify
      end
    end

    context 'with receiver without email' do
      let(:user_data) { super().merge email: nil }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        consumer.notify
      end
    end

    context 'with no welcome mail' do
      let(:course_response) do
        Stub.json({
          id: course_id,
          title: 'some title',
          welcome_mail: '',
        })
      end

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        consumer.notify
      end
    end

    context 'with default notification key' do
      let(:key) { 'test.default' }

      it 'sends email' do
        expect(NotificationService::CourseWelcomeMailer).to receive(:welcome_mail)
        consumer.notify
      end
    end

    context 'with globally email disabled' do
      let(:preferences) { {'notification.email.global' => 'false'} }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        consumer.notify
      end
    end
  end
end
