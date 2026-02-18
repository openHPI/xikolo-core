# frozen_string_literal: true

class Course::Enrollments::CompletionController < Abstract::FrontendController
  before_action :ensure_logged_in

  rescue_from ActionController::ParameterMissing do
    raise AbstractController::ActionNotFound
  end

  def create
    enrollment = Course::Enrollment.find(params[:id])
    raise Status::Unauthorized.new unless current_user.id == enrollment.user_id

    enrollment.update!(completed: true)
    add_flash_message :success, t(:'flash.success.course_archived')
    redirect_to dashboard_path, status: :see_other
  end
end
