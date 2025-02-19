# frozen_string_literal: true

class DashboardController < Abstract::FrontendController
  include ActionView::Helpers::TranslationHelper
  include IcalHelper

  require_feature 'gamification', only: :achievements

  before_action :set_no_cache_headers
  before_action :ensure_logged_in

  include Interruptible

  def index
    redirect_to action: :dashboard
  end

  ### Dashboard ###

  def dashboard
    if params[:authorization]
      # You get a authorization parameter when a user has signed up with
      # e.g. company SSO and a new user account was created on-the-fly.
      # TODO: Show some fancy notice to set a password
      @authorization = Xikolo::Account::Authorization.find params[:authorization]
    end

    load_sidebar_content!
    Acfs.run

    # Load all of the user's enrollments into a hash (keyed by course ID) so that
    # they can be looked up and passed into each course's card component.
    # This is needed for action buttons on the cards being rendered depending on
    # whether an enrollment exists, it's reactivated, etc.
    enrollments = Course::Enrollment.active.where(user_id: current_user.id)

    enrollment_types = {
      active: enrollments.reject(&:completed?),
      completed: enrollments.select(&:completed?),
    }

    courses = Catalog::Course.released
    @categories = categorize(courses, enrollment_types)
    @enrollments = enrollments.index_by(&:course_id)

    set_page_title t(:'header.navigation.my_things')

    render layout: 'dashboard'
  end

  def achievements
    user = Account::User.find current_user.id
    @gamification = Gamification::DashboardPresenter.new(user)
  end

  def documents
    @documents = []
    Xikolo::Course::Enrollment.each_item(
      user_id: current_user.id,
      deleted: true,
      learning_evaluation: true
    ) do |enrollment|
      next unless enrollment.certificates.values.any?

      @documents << DocumentsPresenter.create(enrollment, current_user)
    end

    preferences = Xikolo::Account::Preferences.find user_id: current_user.id
    Acfs.run
    @documents_preferences = preferences.properties['records.show_birthdate']
  end

  private

  Category = Struct.new(:title, :courses, :empty_msg, :completed_button)
  private_constant :Category

  def categorize(courses, enrollments)
    [
      Category.new(
        t(:'dashboard.courses.current'),
        courses.active_for(current_user, enrollments[:active]),
        nil,
        true
      ),
      Category.new(
        t(:'dashboard.courses.upcoming'),
        courses.upcoming_for(current_user, enrollments[:active]),
        t(:'dashboard.not_enrolled_upcoming'),
        false
      ),
      Category.new(
        t(:'dashboard.courses.completed'),
        courses.completed_for(current_user, enrollments[:completed]),
        nil,
        false
      ),
    ].reject do |category|
      # Only display categories that have courses to be shown.
      # NOTE: We call load to prevent additional queries (for existence) before
      # later loading the actual records when displaying them.
      # Always display categories with a relevant empty state.
      category.courses.load.empty? && category.empty_msg.blank?
    end
  end

  def load_sidebar_content!
    @my_promoted = fetch_promoted_courses

    next_dates = Xikolo.api(:course).value!.rel(:next_dates).get(user_id: current_user.id)

    @ical_url = ical_url(current_user, full_path: true)

    Acfs.run

    # Only show next dates for courses starting in the next 2 month
    # next_dates = next_dates.select { |d| ((d.date - DateTime.now) / 30).round <= 2 }

    @next_dates = next_dates.value!.map do |next_date|
      Course::NextDatePresenter.new next_date
    end
  end

  def fetch_promoted_courses
    my_enrollments = Xikolo::Course::Enrollment.where(
      user_id: current_user.id,
      learning_evaluation: true
    )
    promoted_courses = Xikolo::Course::Course.where(promoted_for: current_user.id)

    course_presenters = []
    Acfs.on promoted_courses, my_enrollments do |courses, enrollments|
      courses.each do |course|
        course_presenters << CoursePresenter.create(course, current_user, enrollments)
      end
    end
    course_presenters
  end
end
