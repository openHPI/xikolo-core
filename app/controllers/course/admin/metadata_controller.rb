# frozen_string_literal: true

class Course::Admin::MetadataController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'course.course.edit'

  def show
    render json: Course::Metadata.find(params[:id]).data
  end

  def edit
    @metadata = Course::Admin::MetadataEditPresenter.for_course(id: params[:course_id])
  end

  def update
    @metadata = Course::Admin::MetadataEditPresenter.for_course(id: params[:course_id])

    Course::Metadata::Store.call(@metadata.to_model, params[:course_metadata]).on do |result|
      result.success do
        add_flash_message :success, t(:'flash.success.course_metadata_updated')
        redirect_to edit_course_metadata_path(course_id: @metadata.course_code)
      end
      result.error do |r|
        r.metadata.errors.each do |error|
          @metadata.errors.add(error.attribute, error.message, **{})
        end

        add_flash_message :error, t(:'flash.error.course_metadata_not_updated')
        render action: :edit
      end
    end
  end

  def destroy
    metadata = Course::Metadata.find(params[:id])
    if metadata.destroy
      add_flash_message :success, t(:'flash.success.course_metadata_deleted')
    else
      add_flash_message :error, t(:'flash.error.course_metadata_not_deleted')
    end

    redirect_to edit_course_metadata_path(course_id: metadata.course.course_code)
  end

  private

  def metadata_params
    params.require(:course_metadata).permit(:skills_upload_id, :educational_alignment_upload_id)
  end

  def hide_course_nav?
    true
  end
end
