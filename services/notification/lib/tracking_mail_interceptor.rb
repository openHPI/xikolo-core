# frozen_string_literal: true

require 'nokogiri'
require 'uri'

class TrackingMailInterceptor
  def self.delivering_email(mail, params)
    image_params = params.merge(logo: true)

    %w[text/plain text/html].each do |type|
      next unless mail.find_first_mime_type(type)

      changes = MailChanges.for_type(type, mail)

      # Append the tracking parameters to both link targets and image sources
      handle_links changes, params
      handle_images changes, image_params

      # Replace the email's HTML part with the manipulated links
      changes.apply! mail
    end

    mail
  end

  class MailChanges
    def self.for_type(type, mail)
      case type
        when 'text/html'
          HtmlEmailChanges.new Nokogiri::HTML mail.html_part.body.raw_source
        when 'text/plain'
          TextEmailChanges.new mail.text_part.body.to_s
      end
    end
  end

  class HtmlEmailChanges
    def initialize(html_document)
      @document = html_document
    end

    def each_link(&)
      each_element('a', 'href', &)
    end

    def each_image(&)
      each_element('img', 'src', &)
    end

    def apply!(mail)
      mail.html_part.body.raw_source.replace @document.to_s
    end

    private

    def each_element(html_element, html_attribute)
      @document.css(html_element).each do |element|
        # Parse URI, skip invalid ones
        uri = begin
          URI.parse(element[html_attribute].to_s)
        rescue
          nil
        end
        next unless uri

        # Determine the URI that should be used for replacement, if any
        uri = yield uri
        next unless uri

        element[html_attribute] = uri.to_s
      end
    end
  end

  class TextEmailChanges
    SCHEMES = %w[http https].freeze

    def initialize(text)
      @text = text
    end

    def each_link
      @text.gsub! URI::DEFAULT_PARSER.make_regexp(SCHEMES) do |match|
        handle_trailing_dot(match) do |uri_string|
          # Parse URI, skip invalid ones
          uri = begin
            URI.parse uri_string
          rescue
            nil
          end
          next uri_string unless uri

          # Determine the URI that should be used for replacement, if any
          uri = yield uri
          next uri_string unless uri

          uri.to_s
        end
      end
    end

    def each_image
      # Text emails have no images, fool!
    end

    def apply!(mail)
      mail.text_part.body.raw_source.replace @text
    end

    private

    def handle_trailing_dot(url)
      return yield(url) unless url.end_with?('.')

      "#{yield url[0..-2]}."
    end
  end

  def self.handle_links(mail, tracking_params)
    mail.each_link do |uri|
      # We add tracking parameters to local links
      if same_origin?(uri)
        merge_params uri, tracking_params
      # External HTTP(S) links are redirected through the go controller so that we can track them
      elsif %w[http https].include? uri.scheme
        uri = URI.parse Xikolo::Common::Tracking::ExternalLink.new(uri.to_s, Xikolo.base_url, tracking_params).to_s
      end

      uri
    end
  end

  def self.handle_images(mail, tracking_params)
    mail.each_image do |uri|
      next unless same_origin?(uri)

      # After parsing the existing query params from the URL, we add the tracking params to it
      merge_params uri, tracking_params
      uri
    end
  end

  def self.same_origin?(uri)
    uri&.absolute? &&
      %w[http https].include?(uri.scheme) &&
      (uri.host == Xikolo.base_url.host)
  end

  def self.merge_params(uri, params)
    return if params.empty?

    old_query = URI.decode_www_form(uri.query.to_s).to_h
    uri.query = URI.encode_www_form old_query.merge(params).to_a
  end
end
