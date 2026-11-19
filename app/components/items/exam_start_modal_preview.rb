# frozen_string_literal: true

module Items
  class ExamStartModalPreview < ViewComponent::Preview
    # Open the modal with the start button. The confirmation link stays in the preview.
    # @param language select { choices: [en, de] }
    # @param pass_percentage number
    # @param displayed_max_points number
    # @param allowed_attempts number
    # @param time_limit_seconds number
    def default(language: 'en', pass_percentage: 70, displayed_max_points: 21, allowed_attempts: 2,
                time_limit_seconds: 3600)
      render_with_template(
        template: 'items/exam_start_modal_preview',
        locals: {
          locale: language,
          component: ::Items::ExamStartModal.new(
            id: 'preview',
            start_path: '#',
            pass_percentage: pass_percentage.to_i,
            displayed_max_points: displayed_max_points.to_i,
            current_allowed_attempts: allowed_attempts.to_i,
            current_time_limit_seconds: time_limit_seconds.to_i
          ),
        }
      )
    end

    # @param language select { choices: [en, de] }
    def large_values(language: 'en')
      default(language:, displayed_max_points: 1260, allowed_attempts: 12, time_limit_seconds: 36_000)
    end
  end
end
