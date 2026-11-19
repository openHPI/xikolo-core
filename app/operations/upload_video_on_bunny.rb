# frozen_string_literal: true

require 'net/http'
require 'uri'

class UploadVideoOnBunny
  BUNNY_API_BASE_URL = 'https://video.bunnycdn.com'

  def initialize(library_id:, video_id:, video_attachment:)
    @library_id = library_id
    @video_id = video_id
    @video_attachment = video_attachment # ActiveStorage attachment
  end

  def call
    @video_attachment.blob.open do |tempfile|
      uri = URI("#{BUNNY_API_BASE_URL}/library/#{@library_id}/videos/#{@video_id}")
      request = Net::HTTP::Put.new(uri)
      request['AccessKey'] = bunny_api_key
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/octet-stream'
      request['Content-Length'] = tempfile.size.to_s
      tempfile.rewind
      request.body_stream = tempfile

      Video::Bunny.request(request)
    end
  end

  private

  def bunny_api_key
    ENV.fetch('BUNNY_VIDEO_API_KEY')
  end
end
