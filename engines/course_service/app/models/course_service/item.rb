# frozen_string_literal: true

module CourseService
class Item < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :items

  scope :video,         -> { where(content_type: 'Video::Video') }
  scope :quiz,          -> { where(content_type: 'QuizService::Quiz') }
  scope :rich_text,     -> { where(content_type: 'CourseService::Richtext') }
  scope :lti_exercise,  -> { where(content_type: 'Lti::Exercise') }
  scope :cmi5,          -> { where(content_type: 'Cmi5::Item') }
  scope :published,     -> { where(published: true) }
  scope :available,     -> { published.started.ongoing }
  scope :was_available, -> { published.started }
  scope :optional,      -> { where(optional: true) }
  scope :mandatory,     -> { where(optional: false) }
  scope :started, lambda {
    where('items.start_date <= ? OR items.start_date IS NULL', Time.zone.now)
  }
  scope :ongoing, lambda {
    where('items.end_date >= ? OR items.end_date IS NULL', Time.zone.now)
  }
  scope :course_order, lambda {
    unscope(:order).joins(:section).order('sections.position').order(:position)
  }
  scope :all_available, lambda {
    joins(:section).available.merge(Section.available)
  }
  scope :open_mode, -> { where(open_mode: true).video }
  scope :user_state, lambda {|user|
    select(
      'items.*',
      Result.select('max(dpoints)')
        .where(user_id: user)
        .where('item_id = items.id')
        .arel.as('result'),
      Visit.select(:updated_at)
        .where(user_id: user)
        .where('item_id = items.id')
        .arel.as('visit'),
      Section.select(:optional_section)
        .where('id = items.section_id')
        .arel.as('in_optional_section')
    )
  }
  scope :with_user_visit, lambda {|user|
    user_visits = Visit.where(user_id: user).arel.as('user_visits')

    joins(
      Visit.arel_table
        .join(user_visits, Arel::Nodes::OuterJoin)
        .on(user_visits[:item_id].eq(Item.arel_table[:id]))
        .join_sources
    ).select(
      'items.*',
      user_visits[:user_id].as('visit_user_id'),
      user_visits[:updated_at].as('visit_updated_at')
    )
  }
  scope :new_for, lambda {|user|
    where.not(id: Visit.select(:item_id).where(user_id: user))
  }
  scope :homeworks, -> { was_available.where exercise_type: 'main' }
  scope :graded, -> { was_available.where exercise_type: %w[main bonus exam] }
  scope :exams, -> { where exercise_type: 'exam' }
  # `where.not(exercise_type: 'exam')` would also drop items with a NULL
  # exercise_type, so use a NULL-safe comparison instead.
  scope :not_exams, -> { where('items.exercise_type IS NULL OR items.exercise_type <> ?', 'exam') }

  CMI5_EXERCISE_TYPES = %w[selftest].freeze

  validates :title, :content_type, :content_id, presence: true
  validates :max_dpoints, numericality: {
    only_integer: true,
    message: 'invalid_format',
    allow_nil: true,
    greater_than_or_equal_to: 0,
  }
  validates :exercise_type,
    presence: {if: -> { quiz? }, message: 'required_when_quiz'}
  validates :exercise_type,
    inclusion: {
      in: CMI5_EXERCISE_TYPES,
      message: 'required_when_scored_cmi5',
    },
    if: :scored_cmi5?
  validate :required_items_exist
  validate :published_exam_is_valid
  validate :exam_requires_quiz_with_pool
  validate :single_exam_per_course

  before_validation :force_exam_open_mode_off

  attribute :open_mode, :boolean,
    default: -> { Xikolo.config.open_mode['default_value'] }

  has_paper_trail

  belongs_to :content,
    polymorphic: true,
    optional: true,
    dependent: :destroy
  belongs_to :section
  acts_as_list scope: :section

  has_one :node,
    class_name: 'CourseService::Structure::Item',
    dependent: :destroy

  has_many :results,
    dependent: :delete_all
  has_many :visits,
    dependent: :delete_all

  after_create :attach_node

  after_commit(on: :create) do
    mark_for_recalculation! if published?
  end

  after_commit(on: :update) do
    mark_for_recalculation! if progress_relevant_change?
  end

  delegate :course, to: :section

  GRADABLE_CONTENT_TYPES = %w[Lti::Exercise QuizService::Quiz].freeze

  # Whether an item counts as completed for the learner's progress, given
  # the user's state for it: gradable items once graded or submitted, all
  # other items once visited. A CMI5 item is gradable when it has max points
  # (max_points > 0); otherwise it counts once visited. Exams are excluded
  # from the completed count (their total is tracked separately).
  def self.completed?(content_type:, user_state:, max_points: nil, exercise_type: nil)
    return false if exercise_type == 'exam'

    if gradable_content_type?(content_type, max_points)
      %w[graded submitted].include?(user_state)
    else
      user_state == 'visited'
    end
  end

  def self.gradable_content_type?(content_type, max_points = nil)
    GRADABLE_CONTENT_TYPES.include?(content_type) ||
      (content_type == 'Cmi5::Item' && max_points.to_f.positive?)
  end

  after_commit(on: :destroy) do
    mark_for_recalculation! if published?
  end

  after_commit do
    NextDate::ItemSubmissionDeadlineSyncJob.perform_later(id)
    NextDate::ItemSubmissionPublishingSyncJob.perform_later(id)
  end

  def course_id
    section.course_id
  end

  def mandatory?
    !optional
  end

  def video?
    content_type == 'Video::Video'
  end

  def quiz?
    content_type == 'QuizService::Quiz'
  end

  def rich_text?
    content_type == 'CourseService::Richtext'
  end

  def lti_exercise?
    content_type == 'Lti::Exercise'
  end

  def cmi5?
    content_type == 'Cmi5::Item'
  end

  def content_type_name
    content_type
  end

  def supports_open_mode?
    new_record? || video?
  end

  # `max_dpoints` is stored internally in decipoints; `max_points` is the
  # unit exposed to users (e.g. in forms and the public API).
  def max_points
    max_dpoints.try(:/, 10.0)
  end

  def max_points=(value)
    self.max_dpoints = value.blank? ? nil : (value.to_f * 10).round
  end

  # Is the content of this item accessible to users at this time?
  def available?
    unlocked? && published?
  end

  # Are the time constraints (start and end date) fulfilled?
  def unlocked?
    return false if effective_start_date&.future?

    if course_archived
      end_date.nil? || end_date.future?
    else
      effective_end_date.nil? || effective_end_date.future?
    end
  end

  def label
    if quiz? && exercise_type == 'exam'
      I18n.t(:'sections.index.label.exam')
    else
      I18n.t(:"sections.index.label.#{content_type_name}")
    end
  end

  # Is this exam still locked for the user, because they have not reached the
  # required amount of course progression (completed mandatory items)?
  # Exams are always locked for users without a computed course progress yet.
  # A `nil` user id (e.g. course admins / preview) never locks the exam.
  def exam_locked_for?(user_id)
    return false unless exam?
    return false if user_id.blank?

    progress = CourseProgress.find_by(course_id:, user_id:)
    return true if progress.nil?

    progress.visits_percentage < exam_unlock_percentage
  end

  # The course progress (in percent) a learner needs to unlock this exam.
  # Exams without a configured threshold fall back to 75%.
  def exam_unlock_percentage
    minimum_progress_percentage || 75
  end

  def lower_item_id(user_id: nil)
    if user_id.present? && !section.course.legacy?
      (prev_id, _next_id) = prev_next_ids(user_id)
      prev_id
    else
      item = higher_items.available.first
      item&.id
    end
  end

  def higher_item_id(user_id: nil)
    if user_id.present? && !section.course.legacy?
      (_, next_id) = prev_next_ids(user_id)
      next_id
    else
      item = lower_items.available.first
      item&.id
    end
  end

  def previous_item(user_id:, preview: false)
    navigation_items_for(user_id, preview:).find_by(id: lower_item_id(user_id: preview ? nil : user_id))
  end

  def next_item(user_id:, preview: false)
    navigation_items_for(user_id, preview:).find_by(id: higher_item_id(user_id: preview ? nil : user_id))
  end

  def previous_section_item(user_id:, preview: false)
    return if lower_item_id(user_id: preview ? nil : user_id).present?

    target_section = adjacent_navigation_section(-1)
    navigation_items_for(user_id, target_section:, preview:).last if target_section
  end

  def next_section_item(user_id:, preview: false)
    return if higher_item_id(user_id: preview ? nil : user_id).present?

    target_section = adjacent_navigation_section(1)
    navigation_items_for(user_id, target_section:, preview:).first if target_section
  end

  def effective_start_date
    [start_date, section.effective_start_date].compact.max
  end

  def effective_end_date
    [end_date, section.effective_end_date].compact.min
  end

  def effective_published
    published && section.published
  end

  # If this item is required for another item, is the fulfillment criterion met?
  def fulfilled_for?(user)
    if rich_text? || video?
      return visits.where(user_id: user.id).any?
    end

    return false if results.where(user_id: user.id).empty?
    return true if max_dpoints.zero?

    score = (Result.best_for(id, user.id).dpoints * 100).fdiv(max_dpoints).floor
    score >= Xikolo.config.required_assessment_threshold
  end

  def submission_deadline_for(user_id)
    enrollment = Enrollment.find_by(user_id:, course:)
    return self[:submission_deadline] unless enrollment&.reactivated?

    [self[:submission_deadline], enrollment.forced_submission_date].compact.max
  end

  # Is the quiz closed for submissions because its deadline passed? The
  # learner's reactivated enrollment postpones it to the forced submission date.
  # Takes the enrollment, so that lists check many items with a single query.
  def quiz_deadline_passed?(enrollment)
    return false unless quiz? && submission_deadline?

    [submission_deadline, enrollment&.forced_submission_date].compact.max.past?
  end

  def submission_deadline_passed?(user_id = nil)
    deadline = user_id ? submission_deadline_for(user_id) : self[:submission_deadline]
    deadline.present? && deadline.past?
  end

  def course_archived
    section.course.status == 'self-paced'
  end

  # An LTI exercise keeps accepting submissions after its deadline when its
  # provider allows it. Such an item counts as fully completed in progress
  # views once it has a result.
  def lti_submission_deadline_passed?
    lti_exercise? &&
      submission_deadline_passed? &&
      content.provider&.allow_access_after_deadline
  end

  def user_state?
    respond_to?(:result) && respond_to?(:visit)
  end

  def user_state
    if !result.nil?
      if submission_publishing_date.nil? || submission_publishing_date.before?(Time.zone.now)
        'graded'
      else
        'submitted'
      end
    elsif !visit.nil?
      'visited'
    else
      'new'
    end
  end

  def graded?
    %w[main bonus exam].include? exercise_type
  end

  def exam?
    exercise_type == 'exam'
  end

  # The exam's pass threshold (a percentage on the quiz content). Only exams
  # have one; other items return nil.
  def pass_percentage
    return nil unless exam?

    content&.pass_percentage
  end

  def user_grade(user_id)
    unless graded?
      raise NotGradedError.new 'User Grades are only supported for graded items'
    end

    results.where(user_id:).order(dpoints: :desc).take
  end

  class NotGradedError < RuntimeError; end

  def accessible_for(user_id:)
    raise ArgumentError.new('user_id must be present') if user_id.blank?

    unless section.course.legacy?
      selector = Structure::UserItemsSelector.new(section.course.node, user_id)

      # The item is not part of a user's branch.
      if selector.items(scope: Item.where(id:)).blank?
        return false
      end
    end

    true
  end

  def for_user!(user_id)
    enrollment = enrollment_for(user_id)
    if enrollment && !enrollment.forced_submission_date.nil? && !submission_deadline.nil?
      @forced_submission_date = enrollment.forced_submission_date
    end
  end

  def enrollment_for(user_id)
    Enrollment.find_by(user_id:, course_id:)
  end

  def effective_submission_deadline
    return submission_deadline unless @forced_submission_date

    return @forced_submission_date if @forced_submission_date > submission_deadline

    submission_deadline
  end

  def stats
    @stats ||= ItemStatistics.new(self)
  end

  def decorate_self
    ItemDecorator.decorate(self).as_json(api_version: 1)
  end

  private

  def scored_cmi5?
    cmi5? && max_dpoints&.positive?
  end

  def required_items_exist
    missing_items = required_item_ids - Item.where(id: required_item_ids).ids
    unless missing_items.empty?
      errors.add(:required_item_ids,
        "must identify an item (failed for: #{missing_items.any? ? missing_items.join(', ') : 'empty item'})")
    end
  end

  def published_exam_is_valid
    return unless published? && quiz? && exercise_type == 'exam'

    quiz = quiz_content
    return unless quiz&.question_pool?
    return if quiz.valid_question_pool?

    errors.add(:base, :invalid_exam)
  end

  # Exams are never available in open mode.
  def force_exam_open_mode_off
    self.open_mode = false if exam?
  end

  def exam_requires_quiz_with_pool
    return unless exam?

    errors.add(:exercise_type, :requires_question_pool) unless quiz_content&.question_pool?
  end

  def quiz_content
    content if quiz?
  end

  def single_exam_per_course
    return unless exam?

    already_present = section.course.items.exams.where.not(id:)
    errors.add(:exercise_type, :exam_already_exists) if already_present.exists?
  end

  def mark_for_recalculation!
    # Mark the item's section for recalculation, which in turn can
    # propagate the change further up in the content tree.
    section.mark_for_recalculation! if section.published?

    if section_changed?
      previous_section = Section.find(previous_changes[:section_id].first)
      previous_section.mark_for_recalculation! if previous_section.published?
    end
  end

  def progress_relevant_change?
    saved_change_to_max_dpoints? ||
      saved_change_to_published? ||
      saved_change_to_optional? ||
      # NOTE: Keep the check for section change *after* the check for changes
      # to `published`. Checking whether the item is published, is an
      # optimization as changes to not published items or sections are
      # irrelevant for the progress.
      (published? && section_changed?)
  end

  def section_changed?
    saved_change_to_section_id? && !saved_change_to_section_id?(from: nil)
  end

  def attach_node
    return if section.course.legacy?

    create_node!(course: section.course, parent: section.node)
  end

  def prev_next_ids(user_id)
    @prev_next_ids ||= begin
      selector = Structure::UserItemsSelector.new(section.node, user_id)
      item_ids = selector.item_nodes.pluck(:item_id)
      i = item_ids.index(id)

      [i > 0 ? item_ids[i - 1] : nil, item_ids[i + 1]]
    end
  end

  def adjacent_navigation_section(offset)
    sections = section.course.sections.published.not_alternative.to_a
    current_section_id = section.child? ? section.parent_id : section.id
    index = sections.index { it.id == current_section_id }
    return if index.nil? || (index + offset).negative?

    sections[index + offset]
  end

  def navigation_items_for(user_id, target_section: section, preview: false)
    items = target_section.items.published
    return items if preview || target_section.course.node.blank?

    Structure::UserItemsSelector.new(target_section.node, user_id).items(scope: items)
  end
end
end
