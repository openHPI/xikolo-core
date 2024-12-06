# frozen_string_literal: true

class FeedsController < Abstract::FrontendController
  def index; end

  def courses
    courses = Xikolo::Course::Course.where public: true, hidden: false, per_page: 250
    Acfs.run

    records = CoursePresenter
      .build_collection(courses, current_user)
      .map(&:as_feed_item)

    render json: {courses: records}
  end
end
