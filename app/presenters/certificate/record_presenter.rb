# frozen_string_literal: true

module Certificate
  class RecordPresenter
    extend Forwardable

    ALLOWED_PURPOSES = %i[show verify].freeze

    def_delegator :@record, :user_id
    def_delegator :@record, :type, :certificate_type
    def_delegator :@record, :verification, :verification_code
    def_delegator :@user, :full_name, :user_name
    def_delegator :@user, :email
    def_delegator :@user, :archived, :user_deleted?
    def_delegator :@course, :id, :course_id
    def_delegator :@course, :title, :course_title
    def_delegator :@course, :teacher_text, :course_teachers
    def_delegators :@course, :course_code, :learning_goals

    def initialize(record, purpose)
      raise ArgumentError.new('Must be a symbol: purpose') unless purpose.is_a?(Symbol)
      raise ArgumentError.new("Unknown purpose: :#{purpose}") unless ALLOWED_PURPOSES.include?(purpose)

      @record = record
      @user = record.user
      @course = record.course
      @purpose = purpose
    end

    attr_reader :purpose

    def course_visual
      ::Course::CourseVisual.new(
        @course.visual&.image_url,
        width: 550,
        alt_text: @course.title
      )
    end

    def date_of_birth?
      @record.render_data.date_of_birth.present?
    end

    def date_of_birth
      I18n.l(@record.render_data.date_of_birth) if date_of_birth?
    end

    def course_dates?
      @course.start_date.present?
    end

    def course_dates
      return unless course_dates?

      if @course.end_date.blank?
        I18n.t(:'verify.course_date_from', start_date: I18n.l(@course.start_date.to_date, format: :short))
      else
        I18n.t(
          :'verify.course_date',
          start_date: I18n.l(@course.start_date.to_date, format: :short),
          end_date: I18n.l(@course.end_date.to_date, format: :short)
        )
      end
    end

    def learning_goals?
      learning_goals.present?
    end

    def certificate_type_i18n
      I18n.t(:"verify.#{certificate_type.underscore}")
    end

    def certificate_requirements
      case certificate_type
        when ::Certificate::Record::ROA
          I18n.t(:'course.courses.show.roa_requirements', roa_threshold: @course.roa_threshold_percentage)
        # when 'Certificate' not yet implemented
        else
          ''
      end
    end

    def score?
      @record.render_data.score.present?
    end

    def score
      return unless score?

      I18n.t(
        :'verify.points',
        points: @record.render_data.score[:points],
        max_points: @record.render_data.score[:max_points],
        percent: @record.render_data.score[:percent]
      )
    end

    def issued_at
      I18n.l(@record.render_data.issue_date)
    end

    def issued_year
      @record.render_data.issue_date.to_datetime.year
    end

    def issued_month
      @record.render_data.issue_date.to_datetime.month
    end

    def top?
      @record.render_data.top_percent.present?
    end

    def top
      I18n.t(:'verify.top', top: @record.render_data.top_percent)
    end

    def additional_records
      return if additional_record_types.blank?

      record_translations = additional_record_types.map do |record_type|
        I18n.t(:"verify.#{record_type.underscore}")
      end.join(', ')

      I18n.t(:'verify.additional_records.info', records: record_translations)
    end

    def eligible_for_badge?
      # Open Badges can only be issued for RoA and Certificate
      %w[Certificate RecordOfAchievement].include? certificate_type
    end

    private

    def additional_record_types
      @additional_record_types ||= ::Certificate::Record
        .where(verification: verification_code)
        .where.not(type: certificate_type)
        .map(&:type)
    end
  end
end
