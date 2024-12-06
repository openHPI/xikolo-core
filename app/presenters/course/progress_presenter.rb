# frozen_string_literal: true

class Course::ProgressPresenter < CourseInfoPresenter
  def self.build(user, course)
    new(
      course:,
      user:,
      progresses: Xikolo::Course::Progress.where(
        user_id: user.id,
        course_id: course.id
      )
    )
  end

  def initialize(*args)
    super
    Acfs.on @progresses do |progresses|
      @course_progress = progresses.pop
      @section_progresses = progresses
    end
  end

  def available?
    @section_progresses.any?
  end

  def course_title
    @course['title']
  end

  def with_bonus_exercises?
    !@course_progress.bonus_exercises.nil?
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
    @section_progresses.map do |section|
      Course::SectionProgressPresenter.new section:, course: @course, user: @user
    end
  end

  def self_test_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.selftest_exercises
  end

  def main_exercise_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.main_exercises
  end

  def bonus_exercise_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.bonus_exercises
  end

  def visits_stats
    Course::ProgressVisitsStatsPresenter.new @course_progress.visits
  end
end
