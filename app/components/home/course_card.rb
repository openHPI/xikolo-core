# frozen_string_literal: true

module Home
  class CourseCard < ApplicationComponent
    def initialize(course, enrollment: nil, user: nil, type: nil)
      @course = course
      @enrollment = enrollment
      @user = user
      @type = type
    end

    renders_many :actions

    private

    def card_type
      if %w[expandable compact].include? @type
        @type
      else
        'expandable'
      end
    end

    def compact_card?
      card_type == 'compact'
    end

    def css_modifiers
      card_type
    end

    def data_attributes
      card_type == 'expandable' ? {behavior: 'expandable'} : {}
    end

    def actions_dropdown?
      actions.present? || (compact_card? && show_reactivation_button?)
    end

    def show_additional_buttons?
      @user.present?
    end

    def show_reactivation_button?
      @user&.feature?('course_reactivation') &&
        CourseReactivation.enabled? &&
        !@enrollment&.reactivated? &&
        @course.reactivation_possible?
    end

    def show_extended_information?
      card_type == 'expandable'
    end

    def label
      if @enrollment&.reactivated?
        I18n.t(:'course.card.label.reactivated')
      end
    end

    VISUAL_SIZES = {
      '(max-width: 575px)': [575, 170],
      '(max-width: 768px)': [738, 170],
      '(min-width: 768px) and (max-width: 991px)': [307, 195],
      '(min-width: 992px)': [314, 195],
    }.freeze

    Source = Struct.new(:media, :srcset)

    def visuals
      default_opts = {resizing_type: 'fill', gravity: 'ce'}

      VISUAL_SIZES.map do |media, size|
        srcset = [
          Imagecrop.transform(fallback_visual, **default_opts, width: size[0], height: size[1]),
          "#{Imagecrop.transform(fallback_visual, **default_opts, width: size[0] * 2, height: size[1] * 2)} 2x",
        ]

        Source.new(media, srcset.join(', '))
      end
    end

    def fallback_visual
      @fallback_visual ||= course_visual || platform_visual_fallback
    end

    def course_visual
      Xikolo::S3.object(@course.visual.image_uri).public_url if @course.visual&.image_uri?
    end

    def platform_visual_fallback
      Xikolo.base_url.join(helpers.asset_path('defaults/course.png')).to_s
    end

    def course_abstract
      Rails::HTML5::SafeListSanitizer.new.sanitize(helpers.render_markdown(@course.abstract), tags: %w[p br])
    end

    def date_label
      return unless Xikolo.config.course_details['show_date_label']

      if end_date&.past?
        return I18n.t(:'course.courses.date.self_paced_since', date: I18n.l(end_date, format: :abbreviated_month_date))
      end

      if end_date.blank?
        return date_label_with_no_end_date
      end

      if start_date.present? && end_date.present?
        return I18n.t(
          :'course.courses.date.range',
          start_date: I18n.l(start_date, format: :abbreviated_month_date),
          end_date: I18n.l(end_date, format: :abbreviated_month_date)
        )
      end

      I18n.t(:'course.courses.date.coming_soon')
    end

    def date_label_with_no_end_date
      if start_date&.past?
        return I18n.t(:'course.courses.date.self_paced_since',
          date: I18n.l(start_date, format: :abbreviated_month_date))
      end

      if start_date&.future?
        return I18n.t(:'course.courses.date.beginning', start_date: I18n.l(start_date, format: :abbreviated_month_date))
      end

      I18n.t(:'course.courses.date.coming_soon')
    end

    def start_date
      @start_date ||= @course.display_start_date.presence || @course.start_date
    end

    def end_date
      @end_date ||= @course.end_date
    end

    def classifier_clusters
      Xikolo.config.course_card&.dig('classifier_clusters') & visible_clusters
    end

    def classifiers
      return if classifier_clusters.blank?

      classifier_clusters
        .map {|c| @course.classifiers(c) }
        .flatten
        .join(', ')
    end

    def visible_clusters
      @visible_clusters ||= Rails.cache.fetch(
        'web/course/clusters/visible',
        expires_in: 30.minutes,
        race_condition_ttl: 1.minute
      ) { ::Course::Cluster.visible.ids }
    end

    def highest_achievable_certificate
      if @course.proctored?
        t(:'course.card.qc_html')
      elsif @course.roa_enabled?
        I18n.t(:'course.card.roa')
      elsif @course.cop_enabled?
        I18n.t(:'course.card.cop')
      end
    end

    def subtitles_for_course
      subtitle_languages = ::Course::Course
        .by_identifier(@course.course_code).take!
        .subtitle_offer

      return unless subtitle_languages&.any?

      # Identify the best language for the user.
      if subtitle_languages.size > 1
        subtitle_languages = LanguagePreferences.new(available_languages: subtitle_languages, user: @user,
          request:).sort
      end

      # Display the available languages in the desired format.
      # Example:
      # - 4 or more languages: "DE, EN, ES, FR & 1 more"
      # - Fewer languages: "DE, EN, ES"
      subtitle_count = subtitle_languages.size
      if subtitle_count > 4
        I18n.t(
          :'course.card.subtitles_more',
          count: subtitle_count - 4,
          subtitle_languages: subtitle_languages.first(4).join(', ')
        )
      else
        I18n.t(
          :'course.card.subtitles',
          subtitle_languages: subtitle_languages.join(', ')
        )
      end
    end
  end
end
