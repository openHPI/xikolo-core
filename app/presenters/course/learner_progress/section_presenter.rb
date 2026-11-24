# frozen_string_literal: true

# A course section with the learner's progress on its items, as listed by the
# course service progresses API.
class Course::LearnerProgress::SectionPresenter
  # @param progress [Hash] a section progress from the progresses API
  # @param course [CourseService::Course]
  # @param current_item_id [String, nil] the item the learner resumes the course at
  # @param locked_item_ids [Array<String>] the items the learner cannot work on,
  #   e.g. quizzes past their submission deadline
  # @param retakable_item_ids [Array<String>] the failed exams the learner can retake
  # @param exam_unlock_percentage [Integer, nil] the course progress (in percent)
  #   the learner needs to unlock the course exam, while it is still locked for them
  def initialize(progress, course, current_item_id: nil, locked_item_ids: [], retakable_item_ids: [], # rubocop:disable Metrics/ParameterLists
                 exam_unlock_percentage: nil)
    @progress = progress
    @course = course
    @current_item_id = current_item_id
    @locked_item_ids = locked_item_ids
    @retakable_item_ids = retakable_item_ids
    @exam_unlock_percentage = exam_unlock_percentage
  end

  def id
    @progress['resource_id']
  end

  def title
    @progress['title']
  end

  # Unavailable sections list no items.
  def items
    @items ||= Array.wrap(@progress['items']).map do |item|
      ItemPresenter.new(item, @course, current: item['id'] == @current_item_id,
        locked: @locked_item_ids.include?(item['id']), retakable: @retakable_item_ids.include?(item['id']))
    end
  end

  # The section with the current item is opened.
  def expanded?
    items.any?(&:current?)
  end

  # Sections cannot be opened before their start date, as they list no items
  # yet, nor while their exam is locked for the learner.
  def locked?
    @progress['available'] == false || exam_unlock_percentage.present?
  end

  # Exam sections hold only exams, which do not count towards the progress.
  def exam?
    items.any? && items.all?(&:exam?)
  end

  # The course progress (in percent) the learner needs to unlock the exam of
  # an exam section, while it is still locked for them. A course has at most
  # one exam, so an exam section holds just that one.
  def exam_unlock_percentage
    @exam_unlock_percentage if exam?
  end

  # Like the course progress, only mandatory items other than exams count
  # towards the section progress.
  def total_items_count
    mandatory_items.size
  end

  def completed_items_count
    mandatory_items.count(&:completed?)
  end

  def completed?
    total_items_count.positive? && completed_items_count == total_items_count
  end

  # The items of alternative sections are listed in their child sections.
  def visible?
    @progress['alternative_state'] != 'parent'
  end

  class ItemPresenter
    include UUIDHelper

    # @param item [Hash] an item of a section progress
    # @param course [CourseService::Course]
    # @param current [Boolean] whether the learner resumes the course at this item
    # @param locked [Boolean] whether the learner cannot work on the item
    # @param retakable [Boolean] whether the learner can retake the failed exam
    def initialize(item, course, current: false, locked: false, retakable: false)
      @item = item
      @course = course
      @current = current
      @locked = locked
      @retakable = retakable
    end

    def title
      @item['title']
    end

    def label
      Course::Item::TypeLabel.from_resource(@item).text
    end

    def icon
      Course::Item::Icon.from_resource(@item).icon_class
    end

    def path
      Rails.application.routes.url_helpers.course_item_path(@course.course_code, short_uuid(@item['id']))
    end

    def current?
      @current
    end

    def optional?
      @item['optional'] == true
    end

    def exam?
      @item['content_type'] == 'QuizService::Quiz' && @item['exercise_type'] == 'exam'
    end

    def completed?
      progress_state.marked?
    end

    # The current item is highlighted even when completed or locked, but a
    # submitted exam shows its outcome, passed or failed.
    # Locked items stay linked, as their page explains the lock.
    def state
      if current? && !submitted_exam?
        :current
      elsif completed?
        :completed
      elsif progress_state.failed?
        :failed
      elsif @locked
        :locked
      else
        :default
      end
    end

    # Learners who have not visited any item yet start with the first one.
    # Failed exams are retaken while possible.
    def action_label
      return I18n.t(:'course.progress.retake_exam') if state == :failed && @retakable
      return unless state == :current

      if @item['user_state'] == 'new'
        I18n.t(:'course.progress.current_item.start')
      else
        I18n.t(:'course.progress.current_item.continue')
      end
    end

    private

    def submitted_exam?
      @item['exercise_type'] == 'exam' && %w[graded submitted].include?(@item['user_state'])
    end

    def progress_state
      @progress_state ||= Course::Item::ProgressState.new(
        content_type: @item['content_type'],
        exercise_type: @item['exercise_type'],
        user_state: @item['user_state'],
        user_points: @item['user_points'],
        max_points: @item['max_points'],
        deadline_passed: @item['deadline_passed'],
        pass_percentage: @item['pass_percentage']
      )
    end
  end

  private

  def mandatory_items
    items.reject {|item| item.optional? || item.exam? }
  end
end
