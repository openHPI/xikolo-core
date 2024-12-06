# frozen_string_literal: true

require 'addressable/uri'

##
# A helper class for safe redirects
#
# To avoid open redirect vulnerabilities, redirects should usually only be
# allowed to our own URLs, e.g. absolute URLs with a known host, or relative
# ones without host.
#
class RedirectURL
  def initialize(str)
    @uri = Addressable::URI.parse(str)
  rescue
    @uri = nil
  end

  def internal?(base)
    return false unless @uri

    relative? || same_origin?(base)
  end

  def to_s
    @uri.to_s
  end

  private

  def relative?
    @uri.host.blank?
  end

  def same_origin?(base)
    begin
      base_uri = Addressable::URI.parse(base)
    rescue
      return false
    end

    base_uri.normalized_authority == @uri.normalized_authority
  end
end
