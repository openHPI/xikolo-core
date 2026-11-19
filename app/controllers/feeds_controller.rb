# frozen_string_literal: true

class FeedsController < Abstract::FrontendController
  def index; end

  def courses
    courses = CourseService::Course.where(published: true).order(:id).limit(250)

    records = CoursePresenter
      .build_collection(courses, current_user)
      .map(&:as_feed_item)

    render json: {courses: records}
  end
end
