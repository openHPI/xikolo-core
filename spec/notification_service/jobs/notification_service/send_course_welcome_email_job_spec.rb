# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationService::SendCourseWelcomeEmailJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let(:user_id)   { '81187fa1-6cfd-4b90-a547-b546e24258b7' }
  let(:course_id) { '11187fa1-6cfd-4b90-a547-b546e24258b7' }

  let(:payload) do
    {
      user_id: user_id,
      course_id: course_id,
    }
  end

  let(:user_data) do
    {
      name: 'John Smith',
      email: 'john.smith@example.org',
      language: 'de',
      archived: false,
    }
  end

  let(:preferences) do
    {
      'notification.email.test.key' => 'true',
      'notification.email.test.key2' => 'false',
    }
  end

  describe '#perform' do
    before do
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return(user_response)

      Stub.request(
        :account, :get, "/users/#{user_id}/preferences"
      ).to_return(
        Stub.json({properties: preferences})
      )

      Stub.request(
        :account, :get, "/users/#{user_id}/features"
      ).to_return Stub.json({})

      Stub.request(
        :course, :get, "/courses/#{course_id}"
      ).to_return(course_response)
    end

    let(:user_response) do
      Stub.json(
        user_data.merge(
          id: user_id,
          features_url: "/account_service/users/#{user_id}/features",
          preferences_url: "/account_service/users/#{user_id}/preferences"
        )
      )
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

      it 'does not raise and does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        expect { perform_job }.not_to raise_error
      end
    end

    context 'with archived receiver' do
      let(:user_data) { super().merge archived: true }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer)
          .not_to receive(:welcome_mail)

        perform_job
      end
    end

    context 'with receiver without email' do
      let(:user_data) { super().merge(email: nil) }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        perform_job
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
        perform_job
      end
    end

    context 'with globally email disabled' do
      let(:preferences) { {'notification.email.global' => 'false'} }

      it 'does not send email' do
        expect(NotificationService::CourseWelcomeMailer).not_to receive(:welcome_mail)
        perform_job
      end
    end

    context 'with valid data' do
      it 'sends the course welcome email' do
        mail_delivery = instance_double(ActionMailer::MessageDelivery)

        allow(NotificationService::CourseWelcomeMailer)
          .to receive(:welcome_mail)
          .with(
            kind_of(NotificationService::Resources::Receiver),
            title: 'some title',
            text: 'welcome to this course'
          )
          .and_return(mail_delivery)

        expect(mail_delivery).to receive(:deliver_now!)

        perform_job
      end
    end
  end
end
