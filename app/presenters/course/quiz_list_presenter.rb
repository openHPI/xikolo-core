# frozen_string_literal: true

# All published quizzes of a course (self-tests, graded and bonus quizzes,
# exams and surveys) that the learner has access to, including upcoming and closed ones,
# with the learner's progress on them, in course order.
class Course::QuizListPresenter
  include Enumerable

  # @param course [CourseService::Course]
  # @param user_id [String]
  # @param progresses [Array<Hash>] section progresses followed by the course
  #   progress, telling which alternative sections the learner takes
  # @param current_item_id [String, nil] the item the learner resumes the course at
  def initialize(course, user_id, progresses, current_item_id: nil)
    @course = course
    @user_id = user_id
    @progresses = progresses
    @current_item_id = current_item_id
  end

  def each(&)
    quizzes.each(&)
  end

  # Quizzes past their submission deadline and locked exams are still within
  # their dates, so other lists of the course items show them too.
  def locked_item_ids
    quizzes.select(&:locked?).map(&:id)
  end

  # The course progress (in percent) the learner needs to unlock the course
  # exam (there is at most one), while it is still locked for them
  def exam_unlock_percentage
    quizzes.filter_map(&:exam_unlock_percentage).first
  end

  # Failed exams the learner can still retake
  def retakable_item_ids
    quizzes.select(&:retakable?).map(&:id)
  end

  private

  def quizzes
    @quizzes ||= quiz_items.map do |item|
      QuizPresenter.new(item, @course, @user_id, enrollment, current: item.id == @current_item_id)
    end
  end

  # A reactivated enrollment postpones the quizzes' submission deadlines.
  def enrollment
    @enrollment ||= CourseService::Enrollment.find_by(course_id: @course.id, user_id: @user_id)
  end

  def quiz_items
    Course::LearnerItems.new(@course, @user_id, @progresses)
      .items(scope: CourseService::Item.quiz)
      .preload(section: :course)
  end

  class QuizPresenter < Course::LearnerItemPresenter
    # @param item [CourseService::Item] with the learner's state (`.user_state` scope)
    # @param course [CourseService::Course]
    # @param user_id [String]
    # @param enrollment [CourseService::Enrollment, nil] the learner's enrollment
    # @param current [Boolean] whether the learner resumes the course at this quiz
    def initialize(item, course, user_id, enrollment, current: false)
      super(item, course, current:)
      @user_id = user_id
      @enrollment = enrollment
    end

    # The current quiz is highlighted even when completed, but a submitted
    # exam shows its outcome, passed or failed.
    def state
      if @current && !submitted_exam?
        :current
      elsif progress_state.marked?
        :completed
      elsif failed?
        :failed
      elsif locked?
        :locked
      else
        :default
      end
    end

    def failed?
      progress_state.failed?
    end

    # Like on the exam page: within its dates and submission deadline, with attempts left.
    def retakable?
      failed? && @item.unlocked? && !@item.quiz_deadline_passed?(@enrollment) && attempts_left?
    end

    # Quizzes are locked outside the time they (and their section) are
    # available, and once their submission deadline passed. Exams are also
    # locked until the learner reached the required course progress.
    def locked?
      !@item.unlocked? || @item.quiz_deadline_passed?(@enrollment) || exam_locked?
    end

    # The course progress (in percent) the learner needs to unlock this exam,
    # while it is still locked for them
    def exam_unlock_percentage
      @item.exam_unlock_percentage if exam_locked?
    end

    private

    def submitted_exam?
      @item.exercise_type == 'exam' && %w[graded submitted].include?(@item.user_state)
    end

    # Once submitted, an exam stays reachable for its results, even if the
    # learner's course progress dropped below the required minimum since.
    def exam_locked?
      %w[graded submitted].exclude?(@item.user_state) && @item.exam_locked_for?(@user_id)
    end

    def attempts_left?
      @item.content&.attempts_left?(@user_id) || false
    end
  end
end
