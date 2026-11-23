# frozen_string_literal: true

module Certificate
  class RenderPreviewDataPresenter < RenderDataPresenter
    def score
      return if @template.certificate_type == ::Certificate::Record::COP

      {
        points: 94.6,
        max_points: 100,
        percent: 94.6,
      }
    end

    def exam_attempts
      return if @template.certificate_type == ::Certificate::Record::COP

      1
    end

    def top_percent
      5
    end

    def issue_date
      Date.current
    end
  end
end
