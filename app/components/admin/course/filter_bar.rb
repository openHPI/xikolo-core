# frozen_string_literal: true

module Admin
  module Course
    class FilterBar < ApplicationComponent
      def initialize(form_action: nil, search_param: nil, content_id: nil, loading_indicator_id: nil)
        @form_action = form_action
        @search_param = search_param
        @content_id = content_id
        @loading_indicator_id = loading_indicator_id
      end

      private

      def filters
        @filters ||= [
          status_filter,
        ].compact
      end

      def course_states
        %w[preparation active archive].map do |state|
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
