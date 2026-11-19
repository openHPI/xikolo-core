# frozen_string_literal: true

module Items
  # The modal a learner sees when starting a course exam for the first time.
  #
  # It shows the exam headline, a short note, the exam facts (total points,
  # attempts, time limit), a timer hint, and the start button.
  class ExamStartModal < ApplicationComponent
    def initialize(
      id:,
      start_path:,
      pass_percentage:,
      displayed_max_points:,
      current_allowed_attempts:,
      current_time_limit_seconds:
    )
      @id = id
      @start_path = start_path
      @pass_percentage = pass_percentage
      @displayed_max_points = displayed_max_points
      @current_allowed_attempts = current_allowed_attempts
      @current_time_limit_seconds = current_time_limit_seconds
    end

    def modal_id
      "start-exam-#{@id}"
    end

    def time
      format_duration(@current_time_limit_seconds)
    end

    private

    def format_duration(seconds)
      return '' if seconds.blank?

      format('%02d:%02d:%02d', seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    end
  end
end
