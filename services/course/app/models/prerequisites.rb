# frozen_string_literal: true

class Prerequisites
  def initialize(course)
    @course = course
  end

  delegate :any?, to: :relations

  def status_for(uid)
    UserStatus.new(@course, relations, uid)
  end

  private

  def relations
    @relations ||= @course.relations.includes(:target_courses)
      .where(kind: %w[requires_roa requires_cop])
  end

  class UserStatus
    def initialize(course, relations, uid)
      @course = course
      @relations = relations
      @uid = uid
    end

    def fulfilled?
      sets.all?(&:fulfilled?)
    end

    def sets
      @sets ||= @relations.map do |relation|
        {
          'requires_roa' => Prerequisites::RoaStatus,
          'requires_cop' => Prerequisites::CopStatus,
        }.fetch(relation.kind).new(relation.target_courses, self)
      end
    end

    def decorate(*)
      PrerequisiteStatusDecorator.new(self, *)
    end

    def enrollments
      @enrollments ||= LearningEvaluation.by_params({learning_evaluation: 'true'}).call(
        Enrollment.where(course: all_courses, user_id: @uid)
      ).each_with_object({}) do |enrollment, hash|
        course = all_courses.find {|c| c.id == enrollment.course_id }
        hash[course] = enrollment
      end
    end

    def enrolled?
      @course.enrollments.active.exists?(user_id: @uid)
    end

    private

    def all_courses
      @all_courses ||= @relations.flat_map(&:target_courses)
    end
  end

  class CopStatus
    def initialize(courses, user)
      @courses = courses
      @user = user
    end

    def required_certificate
      'cop'
    end

    def fulfilled?
      @courses.any? do |c|
        @user.enrollments[c] && c.confirmation_of_participation?(@user.enrollments[c])
      end
    end

    def free_reactivation?
      false
    end

    def representative
      @representative ||= sorted_courses.find do |c|
        @user.enrollments[c] && c.confirmation_of_participation?(@user.enrollments[c])
      end || sorted_courses.first
    end

    def score
      fulfilled?
    end

    private

    def sorted_courses
      @sorted_courses ||= @courses.sort_by(&:start_date).reverse!
    end
  end

  class RoaStatus
    def initialize(courses, user)
      @courses = courses
      @user = user
    end

    def required_certificate
      'roa'
    end

    def fulfilled?
      @courses.any? do |c|
        @user.enrollments[c] && c.record_of_achievement?(@user.enrollments[c])
      end
    end

    def free_reactivation?
      representative.allows_reactivation? &&
        !@user.enrollments[representative]&.was_reactivated? &&
        !fulfilled?
    end

    # The newest course with RoA or the newest course
    def representative
      @representative ||= sorted_courses.find do |c|
        @user.enrollments[c] && c.record_of_achievement?(@user.enrollments[c])
      end || sorted_courses.first
    end

    def score
      @user.enrollments[representative].points_percentage if fulfilled?
    end

    private

    def sorted_courses
      @sorted_courses ||= @courses.sort_by(&:start_date).reverse!
    end
  end
end
