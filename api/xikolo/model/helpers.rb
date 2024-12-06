# frozen_string_literal: true

module Xikolo
  module Model
    module Helpers
      def course_repo
        @course_repo ||= Xikolo::Model::CourseRepository.new
      end

      def preference_repo
        @preference_repo ||= Xikolo::Model::PreferenceRepository.new
      end

      # Retrieve all resources, across multiple pages
      def get_paged!(cur_page)
        all = []
        loop do
          all += cur_page
          break unless cur_page.rel?(:next)

          cur_page = cur_page.rel(:next).get.value!
        end
        all
      end
    end
  end
end
