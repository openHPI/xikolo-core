# frozen_string_literal: true

class Course::Admin::OpenBadgeTemplatesController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'certificate.template.manage'

  def index
    course = Course::Course.by_identifier(params[:course_id]).take!
    @template = Certificate::OpenBadgeTemplate.find_by(course:)
  end

  def new
    @template = Certificate::OpenBadgeTemplate.new
    @file_upload = FileUpload.new purpose: :certificate_openbadge_template, content_type: 'image/png'
  end

  def edit
    @template = Certificate::OpenBadgeTemplate.find(params[:id])
    @file_upload = FileUpload.new purpose: :certificate_openbadge_template, content_type: 'image/png'
  end

  def create
    course = Course::Course.by_identifier(params[:course_id]).take!
    @template = Certificate::OpenBadgeTemplate.new(template_params.merge(course_id: course.id))
    @template.process_upload! upload_params[:file_upload_id]

    if @template.save
      add_flash_message :success, t(:'flash.success.open_badge_template_created')
      redirect_to course_open_badge_templates_path
    else
      add_flash_message :error, t(:'flash.error.open_badge_template_not_created')
      @file_upload = FileUpload.new purpose: :certificate_openbadge_template, content_type: 'image/png'
      render action: :new
    end
  end

  def update
    @template = Certificate::OpenBadgeTemplate.find(params[:id])
    @template.assign_attributes template_params.except(:course_id)
    @template.process_upload! upload_params[:file_upload_id]

    if @template.save
      add_flash_message :success, t(:'flash.success.open_badge_template_updated')
      redirect_to course_open_badge_templates_path
    else
      add_flash_message :error, t(:'flash.error.open_badge_template_not_updated')
      @file_upload = FileUpload.new purpose: :certificate_openbadge_template, content_type: 'image/png'
      render action: :edit
    end
  end

  def destroy
    @template = Certificate::OpenBadgeTemplate.find(params[:id])
    if @template.destroy
      add_flash_message :success, t(:'flash.success.open_badge_template_deleted')
    else
      add_flash_message :error, t(:'flash.error.open_badge_template_not_deleted')
    end

    redirect_to course_open_badge_templates_path
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def template_params
    params.require(:open_badge_template).permit(
      :name,
      :description
    )
  end

  def upload_params
    params.require(:open_badge_template).permit(:file_upload_id)
  end
end
