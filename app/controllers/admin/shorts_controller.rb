# frozen_string_literal: true

class Admin::ShortsController < Admin::BaseController
  def index
    authorize! 'course.short.index'

    shorts = CourseService::Short.order(:id)

    if params[:status].present?
      shorts = shorts.where(status: params[:status])
    end

    if params[:autocomplete].present?
      query = ActiveRecord::Base.sanitize_sql_like(params[:autocomplete].to_s)
      locale = I18n.locale.to_s
      shorts = shorts.where('title_translations ->> ? ILIKE ?', locale, "%#{query}%")
    end

    @shorts = shorts.paginate(page: params[:page])
  end

  def new
    authorize! 'course.short.create'
    @short = CourseService::Short.new
  end

  def edit
    authorize! 'course.short.edit'
    @short = CourseService::Short.find(params[:id])
  end

  def create
    authorize! 'course.short.create'

    @short = CourseService::Short.new(short_params)

    if @short.save
      UploadVideoToBunnyJob.perform_later(@short.id) if @short.video.attached?
      add_flash_message :success, t(:'flash.success.short_created')
      redirect_to admin_shorts_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.short_not_created')
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    authorize! 'course.short.edit'

    @short = CourseService::Short.find(params[:id])
    @short.assign_attributes(short_params)

    if @short.save
      UploadVideoToBunnyJob.perform_later(@short.id) if short_params[:video].present? && @short.video.attached?
      add_flash_message :success, t(:'flash.success.short_updated')
      redirect_to admin_shorts_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.short_not_updated')
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize! 'course.short.delete'
    short = CourseService::Short.find(params[:id])
    short.destroy
    redirect_to admin_shorts_path, success: t(:'flash.success.short_deleted'), status: :see_other
  end

  private

  def short_params
    params.require(:short).permit(*CourseService::Short.localized_title_fields,
      *CourseService::Short.localized_description_fields, :status, :course_id, :video)
  end
end
