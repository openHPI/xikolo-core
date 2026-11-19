# frozen_string_literal: true

module Video
  class BunnyAdapter
    def initialize(provider)
      @provider = provider
    end

    def safe_metadata
      {}
    end

    def remove_subtitles!(*); end
    def attach_subtitles!(*); end
    def sync(*); end
    def sync_single(*); end

    def downloads_expire?
      false
    end

    def get_download_links(*)
      nil
    end
  end
end
