# frozen_string_literal: true

module Admin
  module Course
    class FilterBar < ApplicationComponent
      def initialize(search_param: :autocomplete)
        @search_param = search_param
      end

      private

      def filters
        @filters ||= [status_filter]
      end

      def course_states
        %w[preparation active hidden upcoming external self_paced].map do |state|
          [I18n.t(:"admin.courses.index.filter.#{state}"), state]
        end
      end

      def status_filter
        Global::FilterBar::Filter.new(:status, t(:'admin.courses.index.filter.status'), course_states,
          selected: params[:status])
      end
    end
  end
end
