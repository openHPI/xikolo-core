# frozen_string_literal: true

module Xikolo::Course
  class Item < Acfs::Resource
    service Xikolo::Course::Client, path: 'items'

    attribute :id, :uuid
    attribute :title, :string
    attribute :start_date, :date_time
    attribute :end_date, :date_time
    attribute :content_type, :string
    attribute :content_id, :uuid
    attribute :section_id, :uuid
    attribute :published, :boolean
    attribute :exercise_type, :string
    attribute :max_points, :float
    attribute :submission_deadline, :date_time
    attribute :submission_publishing_date, :date_time
    attribute :show_in_nav, :boolean
    attribute :position, :integer
    attribute :next_item_id, :uuid
    attribute :prev_item_id, :uuid
    attribute :effective_start_date, :date_time
    attribute :effective_end_date, :date_time
    attribute :course_archived, :boolean
    attribute :user_state, :string
    attribute :proctored, :boolean
    attribute :optional, :boolean, default: false
    attribute :icon_type, :string
    attribute :featured, :boolean, default: false
    attribute :public_description, :string
    attribute :open_mode, :boolean, default: -> { Xikolo.config.open_mode['default_value'] }
    attribute :time_effort, :integer
    attribute :required_item_ids, :list

    def published?
      published
    end

    def available?
      unlocked? && published?
    end

    def was_available?
      was_unlocked? && published?
    end

    def unlocked?
      if course_archived
        (effective_start_date.nil? || effective_start_date <= Time.zone.now) &&
          (end_date.nil? || end_date >= Time.zone.now)
      else
        (effective_start_date.nil? || effective_start_date <= Time.zone.now) &&
          (effective_end_date.nil? || effective_end_date >= Time.zone.now)
      end
    end

    def was_unlocked?
      effective_start_date.nil? || effective_start_date <= Time.zone.now
    end

    def submission_deadline_passed?
      submission_deadline && submission_deadline < ::Time.zone.now
    end

    def skip_quiz_instructions?
      %w[selftest survey].include?(exercise_type)
    end

    def supports_featured?
      new_record? || (content_type == 'video')
    end

    def supports_open_mode?
      new_record? || (content_type == 'video')
    end
  end
end
