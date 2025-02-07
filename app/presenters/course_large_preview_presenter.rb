# frozen_string_literal: true

class CourseLargePreviewPresenter < CourseInfoPresenter
  attr_reader :video

  def self.build(course, user, enrollments = nil)
    new(course:, user:, enrollments:).tap(&:video!)
  end

  def video!
    return unless visual&.video

    @video = VideoPresenter.new(
      video: visual.video,
      user: @user
    )
  end

  def unenrollment_enabled?
    # unenrollment is enabled for non-invite-only courses
    return true unless @course.invite_only

    # unenrollment is disabled if the course is invite-only
    # and has an external_registration_url
    @course.external_registration_url.blank?
  end

  def access_allowed?
    # is always visible if user is allowed to preview content
    return true if @user.allowed? 'course.content.access'
    # is always hidden if user is not logged in
    return false if @user.anonymous?

    # hide course nav for upcoming courses
    @course.was_available? && @course.external_course_url.blank?
  end

  def proctoring_context
    @proctoring_context ||= Proctoring::CourseContext.new @course, enrollment
  end

  def proctoring_enabled?
    @user.feature?('proctoring') && proctoring_context.enabled?
  end

  def upgrade_proctoring?
    @upgrade_proctoring ||= @user.feature?('proctoring') &&
                            proctoring_context.can_enable?
  end

  def proctoring_upgrade_possible?
    # The #upgrade_possible? needs to be guarded by #upgrade_proctoring?
    # to ensure all preconditions are met. This is done here to not rely
    # on the order of calls in the views.
    upgrade_proctoring? && proctoring_context.upgrade_possible?
  end

  def show_proctoring_impossible_message?
    upgrade_proctoring? && !proctoring_context.upgrade_possible?
  end

  def show_smowl_registration_notice?
    return false unless @user.feature?('proctoring')

    enrollment = Course::Enrollment.active.find_by!(user_id: @user.id, course_id: @course.id)
    enrollment.proctoring.vendor_registration.required?
  end
end
