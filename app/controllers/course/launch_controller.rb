# frozen_string_literal: true

class Course::LaunchController < ApplicationController
  before_action :set_no_cache_headers

  def launch
    raise Status::NotFound unless course

    if current_user.authenticated?
      return redirect_to create_enrollment_path(course_id: course['course_code']), status: :see_other
    end

    store_location create_enrollment_path(course_id: course['course_code'])

    unless params[:auth]
      unless Login.external?
        add_flash_message :notice, t(:'flash.notice.login_to_enroll', course: course['title'])
      end
      return redirect_external login_url
    end

    redirect_to auth_path(params[:auth]), status: :see_other
  end

  private

  def course
    @course ||= Xikolo.api(:course)
      .value!
      .rel(:course)
      .get({id: params[:course_id]})
      .value
  end
end
