# frozen_string_literal: true

module Admin
  module Short
    class FilterBar < ApplicationComponent
      def initialize(search_param: :autocomplete)
        @search_param = search_param
      end

      private

      def filters
        @filters ||= [status_filter]
      end

      def short_states
        %w[preparation active archived].map do |state|
          [I18n.t(:"admin.shorts.index.filter.#{state}"), state]
        end
      end

      def status_filter
        Global::FilterBar::Filter.new(:status, t(:'admin.shorts.index.filter.status'), short_states,
          selected: params[:status])
      end
    end
  end
end
