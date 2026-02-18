# frozen_string_literal: true

class Course::Admin::CertificateTemplatesController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'certificate.template.manage'

  def index
    course = Course::Course.by_identifier(params[:course_id]).take!
    @templates = Certificate::Template.where(course:).map do |template|
      Course::CertificateTemplatePresenter.new(template)
    end
  end

  def new
    course = Course::Course.by_identifier(params[:course_id]).take!
    @template = Certificate::Template.new(course_id: course.id)
    @file_upload = FileUpload.new purpose: :certificate_template, content_type: 'application/pdf'
  end

  def edit
    @template = Certificate::Template.find(params[:id])
    @file_upload = FileUpload.new purpose: :certificate_template, content_type: 'application/pdf'
  end

  def create
    course = Course::Course.by_identifier(params[:course_id]).take!
    @template = Certificate::Template.new(template_params.merge(course_id: course.id))
    @template.process_upload! upload_params[:file_upload_id]

    if @template.save
      add_flash_message :success, t(:'flash.success.certificate_template_created')
      redirect_to course_certificate_templates_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.certificate_template_not_created')
      @file_upload = FileUpload.new purpose: :certificate_template, content_type: 'application/pdf'
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @template = Certificate::Template.find(params[:id])
    @template.assign_attributes template_params.except(:course_id)
    @template.process_upload! upload_params[:file_upload_id]

    if @template.save
      add_flash_message :success, t(:'flash.success.certificate_template_updated')
      redirect_to course_certificate_templates_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.certificate_template_not_updated')
      @file_upload = FileUpload.new purpose: :certificate_template, content_type: 'application/pdf'
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template = Certificate::Template.find(params[:id])
    if @template.records.any?
      add_flash_message :error, t(:'flash.error.certificate_template_has_records')
    elsif @template.destroy
      add_flash_message :success, t(:'flash.success.certificate_template_deleted')
    else
      add_flash_message :error, t(:'flash.error.certificate_template_not_deleted')
    end

    redirect_to course_certificate_templates_path, status: :see_other
  end

  def preview_certificate
    course = Course::Course.by_identifier(params[:course_id]).take!
    preview = Certificate::Template.find(params[:id]).preview_for(current_user.id)

    send_data(
      Certificate::Record::Render.call(preview),
      type: 'application/pdf',
      disposition: 'attachment',
      filename: "#{course.course_code}_record_preview.pdf"
    )
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def template_params
    params.require(:certificate_template).permit(
      :certificate_type,
      :dynamic_content,
      :qrcode_x,
      :qrcode_y
    )
  end

  def upload_params
    params.require(:certificate_template).permit(:file_upload_id)
  end
end
