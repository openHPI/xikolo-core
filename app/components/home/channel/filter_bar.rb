# frozen_string_literal: true

module Home
  module Channel
    class FilterBar < ApplicationComponent
      def initialize(user: nil, results_count: nil)
        @user = user
        @results_count = results_count
      end

      private

      def filters
        @filters ||= [
          language_filter,
          *cluster_filters,
        ].compact
      end

      def language_filter
        course_languages = Xikolo.config.course_languages
        return if course_languages.count < 2

        LanguagePreferences.new(available_languages: course_languages, user: @user, request:)
          .for_filter(selected_language: params[:lang])
      end

      def cluster_filters
        ::Course::Cluster.all.map do |cluster|
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
end
