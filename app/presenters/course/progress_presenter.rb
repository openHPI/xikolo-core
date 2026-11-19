# frozen_string_literal: true

class Course::ProgressPresenter < CourseInfoPresenter
  def self.build(user, course)
    new(course:, user:)
  end

  def available?
    sections.any?
  end

  def open_mode?
    # We check this, because @user can be an instance of either
    # Xikolo::Common::Auth::CurrentUser or Xikolo::Account::User
    # The latter is used when a teacher inspects student progress
    # and has no allowed_any? method
    return false unless @user.respond_to?(:allowed_any?)

    !@user.allowed_any?('course.content.access', 'course.content.access.available')
  end

  def sections
    @sections ||= @course.sections.published.not_alternative.map do |section|
      Course::SectionProgressPresenter.new section:, course: @course, user: @user
    end
  end
end
