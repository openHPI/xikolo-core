# frozen_string_literal: true

class WelcomeMailConsumer < Msgr::Consumer
  def notify
    return if course['welcome_mail'].blank?
    return unless receiver.notify_global?

    CourseWelcomeMailer.welcome_mail(
      receiver,
      title: course['title'],
      text: course['welcome_mail']
    ).deliver_now!
  rescue Restify::NotFound
    # Ignore errors for HTTP 404 responses
    false
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError
    # trace this?
  end

  private

  def receiver
    @receiver ||= Resources::Receiver.load_by_id payload.fetch(:user_id)
  end

  def course
    @course ||= Xikolo.api(:course).value!
      .rel(:course).get({id: payload.fetch(:course_id)}).value!
  end
end
