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

      # The site configuration holds a list of available course content languages
      # The user's preferred languages (user profile language + http accept languages) will be
      # displayed first, followed by the rest in alphabetical order.
      def language_filter
        course_languages = Xikolo.config.course_languages
        return if course_languages.count < 2

        user_preferred_languages = compatible_user_languages(course_languages)
        course_languages_without_preferred = course_languages
          .reject {|l| user_preferred_languages.include? l }

        if user_preferred_languages.empty?
          languages = localize_languages(course_languages).sort
        elsif course_languages_without_preferred.empty?
          languages = localize_languages(user_preferred_languages)
        else
          languages = localize_languages(user_preferred_languages) +
                      [t(:'components.filter_bar.filter.divider')] +
                      localize_languages(course_languages_without_preferred).sort
        end

        Global::FilterBar::Filter.new(:lang, t(:'course.courses.index.filter.language'), languages,
          selected: params[:lang])
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

      def compatible_user_languages(available_languages)
        if @user&.logged_in? && available_languages.include?(@user.preferred_language)
          ([@user.preferred_language] + http_accept_languages).uniq
        else
          http_accept_languages
        end
      end

      def http_accept_languages
        # The Accept-Language request HTTP header returns the language preferred
        # by the client. The http_accept_languages gem helps to parse
        # the values and returns an array of the user's preferred languages.
        # Example: ["en-US", "en", "es-AR", "es", "de"]
        http_accept_languages = HttpAcceptLanguage::Parser.new(request.env['HTTP_ACCEPT_LANGUAGE'])
        user_preferred_languages = http_accept_languages.user_preferred_languages

        # Drop languages that are not included in course_languages config
        # If the language is a variant (e.g. "de-CH"), check for support for its parent
        # language (e.g. "de") before dropping it and remove dupplicates.
        # Result for the sample from above: ["en", "es", "de"]
        available_languages = Xikolo.config.course_languages
        compatible_languages = compatible_languages_from(user_preferred_languages, available_languages)
        compatible_languages.uniq
      end

      def compatible_languages_from(user_preferred_languages, available_languages)
        user_preferred_languages.filter_map do |preferred| # Example: en-US
          preferred = preferred.downcase
          preferred_language = preferred.split('-', 2).first

          available_languages.find do |available| # Example: en
            available = available.to_s.downcase
            preferred == available || preferred_language == available.split('-', 2).first
          end
        end
      end

      def localize_languages(languages)
        languages.map do |lang|
          platform_localization = I18n.t("languages.title.#{lang}")
          native_localization = I18n.t("languages.name.#{lang}")

          ["#{platform_localization} (#{native_localization})", lang]
        end
      end
    end
  end
end
