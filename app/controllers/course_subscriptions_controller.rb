# frozen_string_literal: true

class CourseSubscriptionsController < ApplicationController
  include CourseContextHelper
  before_action :ensure_logged_in

  def create
    Xikolo.api(:pinboard).value!
      .rel(:course_subscriptions)
      .post({user_id: current_user.id, course_id: params[:course_id]}).value!

    redirect_back(fallback_location: course_pinboard_index_path(the_course.course_code), status: :see_other)
  end

  def destroy
    Xikolo.api(:pinboard).value!
      .rel(:course_subscription)
      .delete({id: params[:id]}).value!

    redirect_back(fallback_location: course_pinboard_index_path(the_course.course_code), status: :see_other)
  end
end
