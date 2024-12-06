# frozen_string_literal: true

require 'jwt'
require 'chunky_png'

class OpenBadgeBakery
  SIGNING_ALGORITHM = 'RS256'

  def initialize(assertion, template_uri, private_key)
    @assertion = assertion
    @template_uri = template_uri
    @private_key = private_key
  end

  def bake
    itxt = ChunkyPNG::Chunk::InternationalText.new('openbadges', signed_assertion)

    datastream = ChunkyPNG::Datastream.from_blob badge_template
    datastream.other_chunks << itxt
    datastream.to_blob
  rescue ChunkyPNG::SignatureMismatch
    false
  end

  private

  def badge_template
    Rails.cache.fetch(@template_uri, expires_in: 1.hour) do
      Typhoeus.get(@template_uri).body
    end
  end

  def signed_assertion
    @signed_assertion ||= JWT.encode(
      @assertion,
      OpenSSL::PKey::RSA.new(@private_key),
      SIGNING_ALGORITHM
    )
  end
end
