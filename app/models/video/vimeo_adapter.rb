# frozen_string_literal: true

module Video
  class VimeoAdapter
    def initialize(provider)
      @provider = provider
    end

    def safe_metadata
      {}
    end

    VIMEO_LANGUAGE_IDENTIFIERS = {
      'cn' => 'zh',
    }.tap do |hash|
      hash.default_proc = proc {|_, key| key }
    end

    def remove_subtitles!(stream, language)
      video = api.get(
        "/videos/#{stream.provider_video_id}",
        params: {fields: 'metadata.connections.texttracks.uri'}
      )

      tracks_uri = video.dig('metadata', 'connections', 'texttracks', 'uri')
      tracks = api.get(tracks_uri)['data']
        .select {|t| t['language'] == VIMEO_LANGUAGE_IDENTIFIERS[language] }
        .select {|t| t['type'] == 'subtitles' }

      tracks.each do |track|
        api.delete(track['uri'])
      end
    rescue Vimeo::API::RequestFailed => e
      return if e.http_status == 404 # The video was removed on Vimeo

      raise
    end

    def attach_subtitles!(stream, subtitle)
      video = api.get(
        "/videos/#{stream.provider_video_id}",
        params: {fields: 'metadata.connections.texttracks.uri'}
      )

      tracks_uri = video.dig('metadata', 'connections', 'texttracks', 'uri')

      # Create a new subtitle text track for the given language
      track = api.post(tracks_uri, body: {
        language: VIMEO_LANGUAGE_IDENTIFIERS[subtitle.lang],
        type: 'subtitles',
      }.compact)

      # Store the actual contents for the text track
      api.put(track['link'], body: subtitle.to_vtt)

      # Mark this text track as active
      api.patch(track['uri'], body: {active: true})
    rescue Vimeo::API::RequestFailed => e
      return if e.http_status == 404 # The video was removed on Vimeo

      raise
    end

    # Fetch information about all videos of the user by querying `/me/videos`
    # See API documentation for more information: https://developer.vimeo.com/api/reference/videos#get_videos
    def sync(since:, full: false, next_page: '/me/videos')
      catch(:done) do
        loop do
          response = api.get(
            next_page,
            params: {
              fields: Vimeo::Video::FIELDS,
              sort: 'modified_time',
            }
          )

          # Data contains all videos of the user
          response.fetch('data').each do |stream_data|
            video = Vimeo::Video.new(stream_data)

            throw :done if !full && video.modified_time.before?(since)

            store video
          end

          next_page = response.dig('paging', 'next')

          # If another page is supposed to be fetched, keep going
          break unless next_page
        end
      end
    end

    def sync_single(video_provider_id)
      response = api.get(
        "/videos/#{video_provider_id}",
        params: {fields: Vimeo::Video::FIELDS}
      )

      vimeo_stream = Vimeo::Video.new(response)

      store vimeo_stream
    end

    def downloads_expire?
      true
    end

    def get_download_links(video_id)
      # Initialize the Vimeo::API with a connection timeout of 2 seconds
      # to avoid blocking all workers with download link requests
      client_opts = {request: {timeout: 2}}

      response = api(client_opts:).get(
        "/videos/#{video_id}",
        params: {fields: Vimeo::Download::FIELDS}
      )

      Vimeo::Download.new response.fetch('download')
    rescue Faraday::ConnectionFailed
      raise Vimeo::API::RequestTimeout.new(2)
    end

    private

    def api(client_opts: {})
      @api ||= Vimeo::API.new @provider.credentials['token'], client_opts:
    end

    # Create or update a stream with the given data
    def store(vimeo_stream)
      record = ::Video::Stream.find_or_initialize_by(provider_video_id: vimeo_stream.id)
      record.update vimeo_stream.to_hash.merge(provider_id: @provider.id)
    end
  end
end
