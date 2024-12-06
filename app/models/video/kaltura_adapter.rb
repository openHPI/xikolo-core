# frozen_string_literal: true

require 'kaltura'

module Video
  class KalturaAdapter
    def initialize(provider)
      @provider = provider
    end

    def safe_metadata
      @provider.credentials.slice('partner_id')
    end

    def sync(since:, full: false)
      # If partial sync is triggered, Kaltura filter is applied for
      # fetching only videos uploaded after the last synchronisation.
      filter = Kaltura::KalturaMediaEntryFilter.new
      filter.created_at_greater_than_or_equal = since if since && !full

      pager = Kaltura::KalturaFilterPager.new
      pager.page_size = 100
      pager.page_index = 1

      loop do
        list = api.client.media_service.list(filter, pager)
        break if list.objects.blank?

        list.objects.each do |entry|
          video = KalturaIntegration::Video.new(entry, api.client, partner_id)

          store video
        end

        # Have we seen all items?
        seen_items = pager.page_index * pager.page_size
        break if seen_items >= list.total_count

        # Move on to next page
        pager.page_index += 1
      end
    rescue Kaltura::KalturaAPIError => e
      if e.code == 'USER_BLOCKED'
        raise ::Video::Provider::AccountInactive
      else # Re-raise the original error if the specific error is not handled.
        raise
      end
    end

    def sync_single(provider_video_id)
      response = api.client.media_service.get(provider_video_id)
      stream = KalturaIntegration::Video.new(response, api.client, response.partner_id)

      store stream
    rescue Kaltura::KalturaAPIError => e
      if e.code == 'USER_BLOCKED'
        raise ::Video::Provider::AccountInactive
      else # Re-raise the original error if the specific error is not handled.
        raise
      end
    end

    def downloads_expire?
      false
    end

    def get_download_links(*)
      # noop
    end

    def attach_subtitles!(*)
      # noop
    end

    def remove_subtitles!(*)
      # noop
    end

    private

    def api
      @api ||= KalturaIntegration::API.new(@provider.credentials)
    end

    def store(stream)
      record = Stream.find_or_initialize_by(provider_video_id: stream.id)

      record.update stream.to_hash.merge(
        provider_id: @provider.id
      )
    end

    def partner_id
      @provider.credentials['partner_id']
    end
  end
end
