# frozen_string_literal: true

module Home
  # Shared filter definitions for the course and channel filter bars.
  module SharedCourseFilters
    private

    def language_filter
      course_languages = Xikolo.config.course_languages
      return if course_languages.count < 2

      LanguagePreferences.new(available_languages: course_languages, user: @user, request:)
        .for_filter(selected_language: params[:lang])
    end

    # Only lists formats with at least one learning unit in the given scope.
    def format_filter(scope)
      available_formats = scope.for_user(@user).distinct.pluck(:course_format)

      formats = ::CourseService::Course.course_formats.slice(*available_formats).to_h do |format, value|
        [t(:"course.formats.#{format}"), value]
      end
      return if formats.size < 2

      Global::FilterBar::Filter.new(:course_format, t(:'course.courses.index.filter.format'), formats,
        selected: params[:course_format])
    end

    def cluster_filters
      ::CourseService::Cluster.all.map do |cluster|
        Global::FilterBar::Filter.new(
          cluster.id.to_sym,
          cluster.title,
          cluster.classifiers.to_h {|c| [c.localized_title, c.title] },
          selected: params[cluster.id],
          visible: cluster.visible
        )
        # sort non-visible clusters at the end
      end.sort_by {|cluster| [cluster.visible ? 0 : 1] }
    end
  end
end
