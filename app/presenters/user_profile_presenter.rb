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
    enrollments = Xikolo::Course::Enrollment.where user_id: @user.id, learning_evaluation: 'true', per_page: 500
    Acfs.run
    enrollments.collect do |enrollment|
      course = Xikolo::Course::Course.find enrollment.course_id
      Acfs.run
      EnrollmentWithCourse.new(course, enrollment)
    end
  end

  def manually_confirmable?
    @current_user.allowed?('account.user.confirm_manually') && !confirmed?
  end
end
