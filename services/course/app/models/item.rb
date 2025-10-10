# frozen_string_literal: true

class Item < ApplicationRecord
  self.table_name = :items

  default_scope { order('items.position ASC') }

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
  scope :open_mode, -> { where(open_mode: true, content_type: 'video') }
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
  scope :graded, -> { was_available.where exercise_type: %w[main bonus] }

  validates :title, :content_type, :content_id, presence: true
  validates :max_dpoints, numericality: {
    only_integer: true,
    message: 'invalid_format',
    allow_nil: true,
    greater_than_or_equal_to: 0,
  }
  validates :submission_deadline,
    presence: {if: :proctored, message: 'required_when_proctored'}
  validates :exercise_type,
    presence: {if: -> { content_type == 'quiz' }, message: 'required_when_quiz'}
  validate :required_items_exist

  attribute :open_mode, :boolean,
    default: -> { Xikolo.config.open_mode['default_value'] }

  has_paper_trail

  belongs_to :section
  acts_as_list scope: :section

  has_one :node,
    class_name: '::Structure::Item',
    dependent: :destroy

  has_many :user_results,
    class_name: 'Result',
    dependent: :delete_all
  has_many :user_visits,
    class_name: 'Visit',
    dependent: :delete_all

  has_many :documents_items, dependent: :delete_all
  has_many :documents, through: :documents_items

  after_create :attach_node

  after_commit(on: :create) do
    mark_for_recalculation! if published?
    Msgr.publish(decorate.as_event, to: 'xikolo.course.item.create')
  end

  after_commit(on: :update) do
    mark_for_recalculation! if progress_relevant_change?
    Msgr.publish(decorate.as_event, to: 'xikolo.course.item.update')
  end

  after_commit(on: :destroy) do
    mark_for_recalculation! if published?
    Msgr.publish(decorate.as_event, to: 'xikolo.course.item.destroy')
  end

  after_commit do
    NextDate::ItemSubmissionDeadlineSyncWorker.perform_async(id)
    NextDate::ItemSubmissionPublishingSyncWorker.perform_async(id)
  end

  def course_id
    section.course_id
  end

  def mandatory?
    !optional
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

  def effective_start_date
    [start_date, section.effective_start_date].compact.max
  end

  def effective_end_date
    [end_date, section.effective_end_date].compact.min
  end

  def effective_published
    published && section.published
  end

  def course_archived
    section.course.status == 'archive'
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
    %w[main bonus].include? exercise_type
  end

  def user_grade(user_id)
    unless graded?
      raise NotGradedError.new 'User Grades are only supported for graded items'
    end

    order = if proctored && enrollment_for(user_id)&.proctored
              {created_at: :desc}
            else
              {dpoints: :desc}
            end

    user_results.where(user_id:).order(order).take
  end

  class NotGradedError < RuntimeError; end

  # Is this item currently available in "open mode"?
  #
  # This checks the item-specific open mode setting as well as a few visibility
  # settings for the item's section and course.
  def open_mode_accessible?
    open_mode &&
      content_type == 'video' &&
      section.course.status != 'preparation' &&
      !section.course.hidden &&
      !section.course.invite_only &&
      section.course.groups.blank?
  end

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

  def required_items_exist
    missing_items = required_item_ids - Item.where(id: required_item_ids).ids
    unless missing_items.empty?
      errors.add(:required_item_ids,
        "must identify an item (failed for: #{missing_items.any? ? missing_items.join(', ') : 'empty item'})")
    end
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
end
