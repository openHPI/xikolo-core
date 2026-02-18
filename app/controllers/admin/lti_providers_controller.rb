# frozen_string_literal: true

class Admin::LtiProvidersController < Admin::BaseController
  require_permission 'lti.provider.manage'

  def index
    @providers = Lti::Provider.global.paginate(page: params[:page], per_page: 10)
  end

  def new
    @provider = Lti::Provider.new
  end

  def edit
    @provider = Lti::Provider.find(params[:id])
  end

  def create
    @provider = Lti::Provider.new lti_provider_params

    if @provider.save
      add_flash_message :success, t(:'flash.success.lti_provider_created')
      redirect_to action: :index, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_created')
      render(action: :new, status: :unprocessable_entity)
    end
  end

  def update
    @provider = Lti::Provider.find(params[:id])

    if @provider.update(lti_provider_params)
      add_flash_message :success, t(:'flash.success.lti_provider_updated')
      redirect_to action: :index, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_updated')
      render(action: :edit, status: :unprocessable_entity)
    end
  end

  def destroy
    provider = Lti::Provider.find(params[:id])
    if provider.destroy
      add_flash_message :success, t(:'flash.success.lti_provider_deleted')
    else
      add_flash_message :error, t(:'flash.error.lti_provider_not_deleted')
    end

    redirect_to action: :index, status: :see_other
  end

  private

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
      :shared_secret
    )
  end
end
