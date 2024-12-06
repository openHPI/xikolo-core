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

    def top_percent
      5
    end

    def issue_date
      Date.current
    end

    def proctoring_image
      return unless @template.certificate_type == ::Certificate::Record::CERT

      Rails.root.join('app', 'assets', 'images', 'certificate', 'user_certificate_image.jpg').to_s
    end

    def transcript_of_records
      return unless @template.certificate_type == 'TranscriptOfRecords'

      [
        [
          I18n.t(:'certificates.transcript_of_records.course', locale: course_lang),
          I18n.t(:'certificates.transcript_of_records.score', locale: course_lang),
        ],
        [
          'Geovisualisierung',
          I18n.t(:'certificates.transcript_of_records.passed', locale: course_lang),
        ],
        ['Internet-Technologien', '100.0%'],
        ['Sicherheit im Internet', '50.0%'],
        [
          I18n.t(:'certificates.transcript_of_records.overall_score', locale: course_lang),
          '75.0%',
        ],
      ]
    end
  end
end
