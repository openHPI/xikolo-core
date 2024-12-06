# frozen_string_literal: true

module Xikolo
  module V2
    class CourseAPI < Grape::API::Instance
      namespace 'courses' do
        route_param :course_id, type: String, desc: 'The course UUID' do
          namespace 'time_effort' do
            mount Endpoint::GetCourseTimeEffort
          end
        end
      end

      namespace 'next_dates' do
        mount Endpoint::ListNextDates
      end

      namespace 'classifiers' do
        mount Endpoint::ListClassifiers
      end
    end
  end
end
