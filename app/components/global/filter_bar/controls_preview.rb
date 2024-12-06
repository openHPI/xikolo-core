# frozen_string_literal: true

module Global
  module FilterBar
    class ControlsPreview < ViewComponent::Preview
      def default
        render Global::FilterBar::Controls.new('/', '#', '#', selected_filters)
      end

      def with_results_count
        render Global::FilterBar::Controls.new('/', '#', '#', selected_filters, results_count: '10')
      end

      # @display padding_bottom "100rem"
      def with_overview_bar
        render Global::FilterBar::Controls.new('/', '#', '#', selected_filters, results_count: '10',
          show_overview: true)
      end

      private

      Filter = Struct.new(:key, :title, :options, :selected)

      def selected_filters
        [Filter.new(:key, 'Select', %w[One Two Three], 'Two')]
      end
    end
  end
end
