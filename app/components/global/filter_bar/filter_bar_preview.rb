# frozen_string_literal: true

module Global
  module FilterBar
    class FilterBarPreview < ViewComponent::Preview
      # Filter Bar
      # ------------
      #
      # The filter bar is a component that allows users to filter the content of a page.
      # The result of the filter is a new request to the server with the new filter params.
      #
      # Is usually used together with the State::Loading component
      # to show a loading state while the request with the new filter params is submitted.
      #
      # See `app/components/global/filter_bar/preview/default.html.slim` for an example.
      # Here we use:
      #
      # - `data-hide-on-submit='#example__content'` to hide the content
      # - `data-show-on-submit='#filter-bar__loading'` to show the loading state
      #
      # Note: There is no backend implementation for this preview,
      # so the content does not actually update in here.
      # Previews here are to show the UI of the filter bar in differnent states.
      def default
        render_with_template(template: 'global/filter_bar/preview/default',
          locals: {path: '', name: 'example', search_param: '', filters:})
      end

      def prefilled
        render_with_template(template: 'global/filter_bar/preview/default',
          locals: {path: '', name: 'with_selection', search_param: 'Hello', filters: selected_filters})
      end

      def prefilled_non_visible
        render_with_template(template: 'global/filter_bar/preview/default',
          locals: {path: '', name: 'with_selection', search_param: '', filters: non_visible_filter})
      end

      def with_custom_blank_option
        render_with_template(template: 'global/filter_bar/preview/default',
          locals: {path: '', name: 'with_custom_blank_option', search_param: '', filters: custom_blank_option})
      end

      def multiple_select
        render_with_template(template: 'global/filter_bar/preview/default',
          locals: {path: '', name: 'with_multiple_select', search_param: '', filters: multi_select})
      end

      private

      def filters
        [Global::FilterBar::Filter.new(:key, 'Select', %w[One Two Three])]
      end

      def selected_filters
        [Global::FilterBar::Filter.new(:key, 'Select', %w[One Two Three],
          selected: 'Two')]
      end

      def non_visible_filter
        [Global::FilterBar::Filter.new(:key, 'Select', %w[One Two Three],
          selected: 'Two', visible: false)]
      end

      def custom_blank_option
        [Global::FilterBar::Filter.new(:key, 'Select', %w[One Two Three],
          blank_option: 'All numbers')]
      end

      def multi_select
        [Global::FilterBar::Filter.new(:key, 'Select', %w[One Two Three],
          multi_select: true)]
      end
    end
  end
end
