# frozen_string_literal: true

class Admin::VideoProvidersController < Abstract::FrontendController
  require_permission 'video.provider.manage'

  def index
    @providers = Video::Provider.all
  end

  def new
    @provider = Video::Provider.new(provider_type: params.require(:type))
  end

  def edit
    @provider = Video::Provider.find params[:id]
  end

  def create
    @provider = Video::Provider.new provider_params
    if @provider.save
      redirect_to admin_video_providers_path, status: :see_other
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def update
    provider = Video::Provider.find params[:id]
    provider.update! provider_params

    redirect_to admin_video_providers_path, status: :see_other
  end

  def destroy
    provider = Video::Provider.find params[:id]
    if provider.destroy
      add_flash_message :success, t(:'flash.success.video_provider_deleted')
    else
      add_flash_message :error, t(:'flash.error.video_provider_not_deleted')
    end

    redirect_to admin_video_providers_path, status: :see_other
  rescue ActiveRecord::DeleteRestrictionError
    add_flash_message :error, t(:'flash.error.video_provider_not_deleted')
    redirect_to admin_video_providers_path, status: :see_other
  end

  private

  def provider_params
    params.require(:video_provider)
      .permit(:name, :provider_type)
      .merge(credentials: credential_params)
  end

  def credential_params
    type = params[:video_provider][:provider_type]
    handler = Video::Provider.new(provider_type: type).type

    params["video_provider_credentials_#{type}"].permit(handler.credential_attributes)
  end
end
