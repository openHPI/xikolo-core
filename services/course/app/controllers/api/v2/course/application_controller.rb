# frozen_string_literal: true

class API::V2::Course::ApplicationController < API::V2::RootController
  def index
    render json: {
      courses_url: api_v2_course_courses_rfc6570,
      course_url: api_v2_course_course_rfc6570,
    }
  end
end
