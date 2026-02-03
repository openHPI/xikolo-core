# frozen_string_literal: true

class LtiProvidersController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'lti.provider.manage'
  respond_to :json

  def index
    Acfs.run # because `inside_course` and before actions need Acfs

    @lti_providers = Lti::Provider.where(course_id: the_course.id)
    @new_lti_provider = Lti::Provider.new
  end

  def create
    filtered_params = filter_privacy(lti_provider_params).merge(course_id: the_course.id)
    @new_lti_provider = Lti::Provider.new filtered_params

    if @new_lti_provider.save
      add_flash_message :success, t(:'flash.success.lti_provider_created')
      redirect_to action: :index
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_created')
      # Load all existing providers for the index action.
      @lti_providers = Lti::Provider.where(course_id: the_course.id)
      render action: :index, status: :unprocessable_entity
    end
  end

  def update
    lti_provider = Lti::Provider.find(params[:id])
    filtered_params = filter_privacy(lti_provider_params)

    if lti_provider.update(filtered_params)
      add_flash_message :success, t(:'flash.success.lti_provider_updated')
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_updated')
    end

    redirect_to action: :index
  end

  def destroy
    lti_provider = Lti::Provider.find(params[:id])
    if lti_provider.destroy
      add_flash_message :success, t(:'flash.success.lti_provider_deleted')
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_deleted')
    end

    redirect_to action: :index
  end

  def hide_course_nav?
    true
  end

  private

  def filter_privacy(params)
    return params if current_user.allowed?('lti.provider.edit_privacy_mode')

    params.except('privacy')
  end

  def auth_context
    the_course.context_id
  end

  def lti_provider_params
    params.require(:lti_provider).permit(
      :consumer_key,
      :custom_fields,
      :description,
      :domain,
      :id,
      :name,
      :presentation_mode,
      :privacy,
      :shared_secret,
      :course_id
    )
  end
end
