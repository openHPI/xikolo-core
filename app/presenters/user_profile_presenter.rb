# frozen_string_literal: true

class UserProfilePresenter
  extend Forwardable

  def_delegators :@user, :name, :full_name, :display_name, :confirmed?, :form, :all_emails, :archived?
  def_delegator :@user, :id, :user_id

  EnrollmentWithCourse = Struct.new(:course, :enrollment)

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
    @preferences = Xikolo::Account::Preferences.find(user_id: user.id)
  end

  def enrolled_courses
    CourseService::Enrollment.with_evaluation
      .active
      .where(user_id: @user.id)
      .map do |enrollment|
      EnrollmentWithCourse.new(enrollment.course, enrollment)
    end
  end

  def manually_confirmable?
    @current_user.allowed?('account.user.confirm_manually') && !confirmed?
  end
end
