# frozen_string_literal: true

module Course
  module Documents
    class FilterBar < ApplicationComponent
      def initialize(documents)
        @documents = documents
      end

      def action
        course_documents_path
      end

      def filters
        @filters ||= [
          language_filters,
          tag_filters,
        ].compact
      end

      private

      def language_filters
        languages = @documents.flat_map do |document|
          document[:localizations].pluck(:language)
        end.uniq

        Global::FilterBar::Filter.new(:language,
          I18n.t(:'knowledge_documents.language'),
          localize_language_options(languages),
          selected: params[:language])
      end

      def localize_language_options(languages)
        languages.map do |lang|
          platform_localization = I18n.t("languages.title.#{lang}")
          native_localization = I18n.t("languages.name.#{lang}")

          ["#{platform_localization} (#{native_localization})", lang]
        end
      end

      def tag_filters
        filters = @documents.pluck(:tags).flatten.compact.uniq
        return if filters.empty?

        Global::FilterBar::Filter.new(:tag,
          I18n.t(:'knowledge_documents.tags'),
          filters,
          selected: params[:tag])
      end
    end
  end
end
