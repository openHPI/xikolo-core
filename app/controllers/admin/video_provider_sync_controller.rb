# frozen_string_literal: true

class Admin::VideoProviderSyncController < Abstract::FrontendController
  require_permission 'video.video.manage'

  def create
    raise SyncRecentlyTriggered if provider.currently_syncing?
    raise SyncRecentlyTriggered if full_sync? && provider.recently_synced?

    Video::SyncVideosJob.perform_later(
      provider: provider.id,
      full: params[:full] == 'true'
    )

    add_flash_message :success, t(:'flash.success.sync_initiated')
    redirect_to video_providers_path
  rescue SyncRecentlyTriggered
    add_flash_message :notice, t(:'flash.error.sync_recently_triggered')
    redirect_to video_providers_path
  end

  class SyncRecentlyTriggered < StandardError; end

  private

  def full_sync?
    params[:full] == 'true'
  end

  def provider
    @provider ||= Video::Provider.find params[:id]
  end
end
