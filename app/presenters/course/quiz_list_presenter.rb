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
    items = CourseService::Item.published.where(content_type: 'quiz')
      .joins(:section).merge(CourseService::Section.published)
      .where(sections: {course_id: @course.id})

    items = if @course.legacy?
              items.where(section_id: taken_section_ids).course_order
            else
              CourseService::Structure::UserItemsSelector.new(@course.node, @user_id).items(scope: items)
            end
    items.user_state(@user_id).preload(section: :course)
  end

  # In legacy courses, the progresses list the sections the learner takes,
  # i.e. without the alternatives they did not choose or that were discarded.
  def taken_section_ids
    Array.wrap(@progresses)
      .select {|progress| progress['kind'] == 'section' && !progress['discarded'] }
      .pluck('resource_id')
  end

  class QuizPresenter
    include UUIDHelper

    # @param item [CourseService::Item] with the learner's state (`.user_state` scope)
    # @param course [CourseService::Course]
    # @param user_id [String]
    # @param enrollment [CourseService::Enrollment, nil] the learner's enrollment
    # @param current [Boolean] whether the learner resumes the course at this quiz
    def initialize(item, course, user_id, enrollment, current: false)
      @item = item
      @course = course
      @user_id = user_id
      @enrollment = enrollment
      @current = current
    end

    def id
      @item.id
    end

    def title
      @item.title
    end

    def label
      Course::Item::TypeLabel.from_resource(@item).text
    end

    def icon
      Course::Item::Icon.from_resource(@item).icon_class
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

    # Quizzes outside their dates have no page for the learner. Quizzes past their
    # deadline and locked exams stay linked, as their page explains the lock.
    def path
      return unless @item.unlocked?

      Rails.application.routes.url_helpers.course_item_path(@course.course_code, short_uuid(@item.id))
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
      QuizService::Quiz.find_by(id: @item.content_id)&.attempts_left?(@user_id) || false
    end

    def progress_state
      @progress_state ||= Course::Item::ProgressState.new(
        content_type: @item.content_type,
        exercise_type: @item.exercise_type,
        user_state: @item.user_state,
        user_points: @item.result&./(10.0),
        max_points: @item.max_points,
        pass_percentage: @item.pass_percentage
      )
    end
  end
end
