# frozen_string_literal: true

module CourseService
class Section < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :sections

  after_initialize :default_values

  scope :available,       -> { was_available.ongoing }
  scope :published,       -> { where(published: true) }
  scope :was_available,   -> { started.published }
  scope :optional,        -> { where(optional_section: true) }
  scope :mandatory,       -> { where(optional_section: false) }

  # In Rails 6, these could use begin-/end-less ranges
  scope :started, lambda  {
    where('sections.start_date <= ? OR sections.start_date IS NULL', Time.zone.now)
  }
  scope :ongoing, lambda {
    where('sections.end_date >= ? OR sections.end_date IS NULL', Time.zone.now)
  }
  scope :not_alternative, -> { where.not(alternative_state: 'child') }

  validates :title, presence: true
  validates :optional_section, exclusion: {in: [nil]}

  has_one :node, class_name: 'CourseService::Structure::Section', inverse_of: :section,
    foreign_key: :section_id, dependent: :destroy # rubocop:disable Rails/RedundantForeignKey

  has_many :items, -> { order(:position) }, inverse_of: :section
  has_many :forks, inverse_of: :section
  has_many :section_progresses, dependent: :destroy
  belongs_to :course
  acts_as_list scope: :course

  belongs_to :parent, -> { where(alternative_state: 'parent') },
    class_name: 'CourseService::Section', foreign_key: :parent_id, optional: true
  has_many :children, -> { where(alternative_state: 'child') },
    class_name: 'CourseService::Section', foreign_key: :parent_id

  after_create :attach_node

  before_destroy -> { throw :abort unless destroyable? }, prepend: true

  # Only mark the section for recalculation on relevant updates.
  # Creation is not relevant as only new items need to be considered.
  after_commit(on: :update) do
    mark_for_recalculation! if progress_relevant_change?
  end

  after_commit(on: :destroy) do
    mark_for_recalculation! if published?
  end

  after_commit do
    NextDate::SectionStartSyncJob.perform_later(id)
    items.pluck(:id).each do |item_id|
      NextDate::ItemSubmissionDeadlineSyncJob.perform_later(item_id)
      NextDate::ItemSubmissionPublishingSyncJob.perform_later(item_id)
    end
  end

  def effective_start_date
    [start_date, course.start_date].compact.max
  end

  def effective_end_date
    end_date
  end

  def fulfilled_for?(user)
    required_items = items.where(optional: false)
    return true if required_items.empty?

    score = (required_items.count {|item| item.fulfilled_for?(user) } * 100).fdiv(required_items.size).floor
    score >= Xikolo.config.required_assessment_threshold
  end

  # Is the content of this section accessible to users at this time?
  def available?
    unlocked? && published?
  end

  # Are the time constraints (start and end date) fulfilled?
  def unlocked?
    return false if effective_start_date&.future?
    return false if end_date&.past?

    true
  end

  def course_archived
    course.status == 'self-paced'
  end

  def parent?
    alternative_state == 'parent'
  end

  def child?
    alternative_state == 'child'
  end

  def optional?
    optional_section?
  end

  def destroyable?
    items.none? && forks.none?
  end

  def goals(user_id)
    SectionGoals.new(self, user_id)
  end

  def alternatives
    return unless parent?

    @alternatives ||= CourseService::Section.where(parent_id: id)
  end

  # rubocop:disable Style/IfInsideElse
  # rubocop:disable Rails/SkipsModelValidations
  def mark_for_recalculation!
    # Mark both the section and the entire course for recalculation.
    if course.legacy?
      update_attribute(:progress_stale_at, Time.current) if persisted?
    else
      node.update_attribute(:progress_stale_at, Time.current) if persisted?
    end

    course.mark_for_recalculation!
  end
  # rubocop:enable all

  def needs_recalculation?
    if course.legacy?
      return true if course.progress_calculated_at.nil?
      return false if progress_stale_at.nil?

      progress_stale_at > course.progress_calculated_at
    else
      node.needs_recalculation?
    end
  end

  private

  def progress_relevant_change?
    saved_change_to_published? || saved_change_to_optional_section?
  end

  def attach_node
    return if course.legacy?

    create_node!(course:, parent: course.node)
  end

  def default_values
    # Access via attributes is necessary as accessing `self.alternative_state`
    # may raise an `ActiveModel::MissingAttributeError` exception.
    self.alternative_state = attributes['alternative_state'] || 'none'
  end
end
end
