# frozen_string_literal: true

module NotificationService
  class SendCourseWelcomeEmailJob < ApplicationJob
    def perform(payload)
      @payload = payload

      return if course['welcome_mail'].blank?
      return unless receiver.notify_global?

      NotificationService::CourseWelcomeMailer.welcome_mail(
        receiver,
        title: course['title'],
        text: course['welcome_mail']
      ).deliver_now!
    rescue Restify::NotFound
      false
    rescue Net::SMTPSyntaxError, Net::SMTPFatalError
    end

    private

    attr_reader :payload

    def receiver
      @receiver ||= Resources::Receiver.load_by_id(payload.fetch(:user_id))
    end

    def course
      @course ||= Xikolo.api(:course).value!
        .rel(:course).get({id: payload.fetch(:course_id)}).value!
    end
  end
end
