# frozen_string_literal: true

require 'net/http'
require 'uri'

class CreateVideoOnBunny
  BUNNY_API_BASE_URL = 'https://video.bunnycdn.com'

  def initialize(library_id:, title:, collection_id: nil)
    @library_id = library_id
    @title = title
    @collection_id = collection_id
  end

  # Returns the video_id (guid) from Bunny on success
  def call
    body = {title: @title}
    body[:collectionId] = @collection_id if @collection_id

    uri = URI("#{BUNNY_API_BASE_URL}/library/#{@library_id}/videos")
    request = Net::HTTP::Post.new(uri)
    request['AccessKey'] = bunny_api_key
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    request.body = body.to_json

    Video::Bunny.request(request).fetch('guid')
  end

  private

  def bunny_api_key
    ENV.fetch('BUNNY_VIDEO_API_KEY')
  end
end
