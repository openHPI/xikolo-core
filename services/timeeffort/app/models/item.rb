# frozen_string_literal: true

class Item < ApplicationRecord
  require 'errors'
  require 'operation'

  self.table_name = 'time_effort_items'

  validates :content_type, :content_id, :section_id, :course_id,
    presence: {message: :required}
  validates :time_effort,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    allow_nil: true
  validates :calculated_time_effort,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    allow_nil: true

  scope :for_section, ->(section_id) { where section_id: }
  scope :for_course, ->(course_id) { where course_id: }

  # rubocop:disable Naming/AccessorMethodName
  def set_calculated_time_effort(time_effort)
    if time_effort == calculated_time_effort
      return Operation.with_errors(time_effort: 'unnecessary_update')
    end

    update_params = {calculated_time_effort: time_effort}
    update_params[:time_effort] = time_effort unless time_effort_overwritten

    update! update_params
    Operation.new
  rescue Errors::Problem => e
    Operation.new.tap {|operation| operation.error! :base, e.reason }
  rescue ActiveRecord::RecordInvalid => e
    Operation.with_errors e.record.errors
  end
  # rubocop:enable all

  def overwrite_time_effort(time_effort)
    update!(time_effort:, time_effort_overwritten: true)
    Operation.new
  rescue ActiveRecord::RecordInvalid => e
    Operation.with_errors e.record.errors
  end

  def clear_overwritten_time_effort
    update!(time_effort: calculated_time_effort, time_effort_overwritten: false)
  end

  def processor
    ITEM_TYPE_PROCESSORS.fetch(content_type).new self
  rescue KeyError
    raise Errors::InvalidItemType
  end

  def calculation_supported?
    ITEM_TYPE_PROCESSORS.key?(content_type)
  end

  ITEM_TYPE_PROCESSORS = {
    'rich_text' => Processors::RichTextProcessor,
    'video' => Processors::VideoProcessor,
    'quiz' => Processors::QuizProcessor,
  }.freeze
end
