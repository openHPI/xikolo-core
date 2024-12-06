# frozen_string_literal: true

class Course::DocumentsPresenter
  def initialize(user_id:, course:, current_user:)
    @user_id = user_id
    @course = BasicCoursePresenter.new(course)
    @current_user = current_user

    documents!
  end

  attr_reader :course

  def documents!
    Xikolo::Course::Enrollment.find_by(
      user_id: @user_id,
      course_id: @course.id,
      learning_evaluation: true
    ) do |enrollment|
      @documents = ::DocumentsPresenter.create(enrollment, @current_user) unless enrollment.nil?
    end
  end

  def cop?
    @documents&.cop?
  end

  def roa?
    @documents&.roa?
  end

  def cert?
    @documents&.cert?
  end

  def tor?
    @documents&.tor?
  end

  def tor_available?
    tor_enabled? && @documents&.tor_available?
  end

  def tor_enabled?
    Xikolo.config.certificate['transcript_of_records'].present?
  end

  def open_badge_enabled?
    @documents&.open_badge_enabled?
  end

  def open_badge?
    @documents&.open_badge?
  end

  def cert_enabled?
    # Certificate
    @documents&.cert_enabled?
  end

  def certificate_download?
    # Certificate
    @documents&.certificate_download?
  end

  def certificate_requirements
    return Array.wrap(I18n.t(:'course.courses.show.tor_requirements')) if tor_available?

    @course.certificate_requirements
  end
end
