# frozen_string_literal: true

module Global
  module FilterBar
    class Controls < ApplicationComponent
      def initialize(path, content_id, loading_indicator_id, filters, results_count: nil, show_overview: false,
                     search_param: :q)
        @path = path
        @content_id = content_id
        @loading_indicator_id = loading_indicator_id
        @filters = filters
        @results_count = results_count
        @show_overview = show_overview
        @search_param = search_param
      end

      private

      # Are we currently filtering?
      def render?
        params[@search_param].present? || @filters.any? {|filter| filter.selected.present? }
      end

      def results_count
        return unless @results_count

        I18n.t(:'components.filter_bar.filter.results_count', count: @results_count)
      end

      def applied_filters
        list = []
        list << params[@search_param]

        @filters.each do |filter|
          next if filter.selected.blank?

          if filter.key == :lang
            list << I18n.t("languages.title.#{filter.selected}")
          elsif filter.options.is_a?(Hash)
            list << filter.options.key(filter.selected)
          else
            list << filter.selected
          end
        end
        list.compact_blank.join(', ')
      end
    end
  end
end
