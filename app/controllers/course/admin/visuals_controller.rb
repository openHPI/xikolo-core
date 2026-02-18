# frozen_string_literal: true

class Course::Admin::VisualsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'course.course.edit'

  def edit
    @visual_presenter = Course::Admin::VisualEditPresenter.for_course(id: params[:course_id])
  end

  def update
    @visual_presenter = Course::Admin::VisualEditPresenter.for_course(id: params[:course_id])

    Course::Visual::Store.call(
      @visual_presenter.visual,
      visual_params.tap {|vp| vp[:image_uri] = nil if delete_image? }
    ).on do |result|
      result.success do
        add_flash_message :success, t(:'flash.success.course_visual_updated')
        if params[:show]
          redirect_to course_path(id: @visual_presenter.course_code), status: :see_other
        else
          redirect_to edit_course_visual_path(course_id: @visual_presenter.course_code), status: :see_other
        end
      end
      result.error do |e|
        case e.message
          when 'subtitles_update_error'
            add_flash_message :error, t(:'flash.error.subtitles_not_updated')
          when 'teaser_video_missing'
            add_flash_message :error, t(:'flash.error.video_stream_missing')
          else
            add_flash_message :error, t(:'flash.error.course_visual_not_updated')
        end

        redirect_to edit_course_visual_path(course_id: @visual_presenter.course_code), status: :see_other
      end
    end
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def request_course
    Xikolo::Course::Course.find params[:course_id]
  end

  def visual_params
    params.require(:course_visual).permit(
      :image_upload_id,
      :image_uri,
      :subtitles_upload_id,
      :video_stream_id
    ).to_h
  end

  def delete_image?
    params.require(:course_visual).fetch(:delete_image, false) == 'true'
  end
end
