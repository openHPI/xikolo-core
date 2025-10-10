# frozen_string_literal: true

class Section < ApplicationRecord
  self.table_name = :sections

  default_scope { order(position: :asc) }
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

  has_one :node, class_name: '::Structure::Section', foreign_key: :section_id, dependent: :destroy # rubocop:disable Rails/RedundantForeignKey

  has_many :items, -> { order(:position) }, inverse_of: :section
  has_many :forks, inverse_of: :section
  has_many :section_progresses, dependent: :destroy
  belongs_to :course
  acts_as_list scope: :course

  belongs_to :parent, -> { where(alternative_state: 'parent') },
    class_name: 'Section', foreign_key: :parent_id, optional: true
  has_many :children, -> { where(alternative_state: 'child') },
    class_name: 'Section', foreign_key: :parent_id

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
    NextDate::SectionStartSyncWorker.perform_async(id)
    items.pluck(:id).each do |item_id|
      NextDate::ItemSubmissionDeadlineSyncWorker.perform_async(item_id)
      NextDate::ItemSubmissionPublishingSyncWorker.perform_async(item_id)
    end
  end

  def effective_start_date
    [start_date, course.start_date].compact.max
  end

  def effective_end_date
    end_date
  end

  def course_archived
    course.status == 'archive'
  end

  def parent?
    alternative_state == 'parent'
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
