# frozen_string_literal: true

require 'addressable'

class ProctoringController < Abstract::FrontendController
  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.voucher['enabled']
  end

  before_action :ensure_logged_in
  before_action :ensure_course_proctored
  before_action :set_no_cache_headers
  before_action :ensure_already_upgraded
  before_action :ensure_not_registered_with_vendor

  layout 'simple'

  def registration_details; end

  def register_at_smowl
    redirect_external(
      enrollment.proctoring.vendor_registration_url(
        redirect_to: course_url(course)
      )
    )
  end

  private

  def ensure_course_proctored
    unless course.proctored?
      add_flash_message :error, t(:'flash.error.proctoring.booking_failed')
      redirect_to course_path(course)
    end
  end

  def ensure_already_upgraded
    unless enrollment.proctored?
      add_flash_message :error, t(:'flash.error.proctoring.booking_failed')
      redirect_to course_path(course)
    end
  end

  def ensure_not_registered_with_vendor
    unless enrollment.proctoring.vendor_registration.required?
      add_flash_message :success, t(:'flash.success.proctoring.already_registered_smowl')
      redirect_to course_path(course)
    end
  end

  def course
    @course ||= Course::Course.by_identifier(params[:course_code] || params[:course_id]).take!
  rescue ActiveRecord::RecordNotFound
    raise Status::NotFound
  end

  def enrollment
    @enrollment ||= course.enrollments.active.find_by!(user_id: current_user.id)
  rescue ActiveRecord::RecordNotFound
    raise Status::NotFound
  end

  def auth_context
    course.context_id
  end
end
