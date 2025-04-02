# frozen_string_literal: true

module Video
  module KalturaIntegration
    class Video
      POSTER_WIDTH = 1280

      def initialize(entry, client, partner_id)
        @entry = entry
        @client = client
        @partner_id = partner_id
        @best_flavor = {}
      end

      def to_hash
        {
          # Generic data
          provider_video_id: @entry.id,
          title: @entry.name,
          height: @entry.height,
          width: @entry.width,
          duration: @entry.duration,
          poster: poster_url,
          updated_at: Time.at(@entry.updated_at).iso8601,

          # HD version
          hd_url: streaming_url(:hd, format: 'url'),
          hd_size: size_by_flavor(:hd),
          hd_md5: updated_at_by_flavor(:hd),
          hd_download_url: download_url(:hd),

          # SD version
          sd_url: streaming_url(:sd, format: 'url'),
          sd_size: size_by_flavor(:sd),
          sd_md5: updated_at_by_flavor(:hd),
          sd_download_url: download_url(:sd),

          # HLS version
          hls_url: streaming_url(:sd, format: 'applehttp'),
        }
      end

      def id
        @entry.id
      end

      private

      ##
      # Build streaming URLs programmatically for each video variant, e.g.
      # "https://cdnapisec.kaltura.com/p/4549393/sp/0/playManifest/entryId/1_jrdhwl7x/
      # format/url/flavorId/487071/name/webtech2021-kombi-teaser-lecturer.mp4".
      # See https://knowledge.kaltura.com/help/how-to-retrieve-the-download-or-streaming-url-using-api-calls.
      #
      def streaming_url(quality, format:)
        return unless best_flavor(quality)

        Addressable::Template.new(
          Xikolo.config.kaltura['asset_url'] +
            '{/partner}/sp/0/playManifest/entryId{/id}/format{/format}' \
            '/protocol{/protocol}/flavorId{/flavor}/name{/name}{extension}'
        ).expand(
          partner: @partner_id,
          id: @entry.id,
          format:,
          protocol: 'https',
          flavor: best_flavor(quality),
          name: @entry.name,
          extension: format == 'url' ? '.mp4' : ''
        ).to_s
      end

      ##
      # Modify download URLs retrieved from Kaltura with an explicit *flavor_id*
      # to refer to the requested quality, e.g. in
      # "https://cdnapisec.kaltura.com/p/4549393/sp/454939300/playManifest/
      # entryId/1_jrdhwl7x/format/download/protocol/https/flavorParamIds/0".
      # Replace the *0* with the explicit *flavor_id*.
      #
      def download_url(quality)
        return unless best_flavor(quality)

        uri = Addressable::URI.parse(@entry.download_url)
        template = Addressable::Template.new('https://{host}{/segments*}/flavorParamIds{/flavor}')
        template.extract(uri).then do |elements|
          if elements.blank?
            raise RuntimeError(
              "Download URL for Kaltura video #{@entry.id} does not match pattern: #{@entry.download_url}"
            )
          end

          template.expand(elements.merge(flavor: best_flavor(quality))).to_s
        end
      rescue RuntimeError => e
        ::Mnemosyne.attach_error(e)
        ::Sentry.capture_exception(e)
        nil
      end

      ##
      # The poster URL is composed from the thumbnail URL and an explicit *width*
      # param. Kaltura generates and caches them server-side.
      #
      def poster_url
        Addressable::Template.new("#{@entry.thumbnail_url}{/segments*}")
          .expand(segments: ['width', POSTER_WIDTH]).to_s
      end

      # The flavor mapping in Xikolo.config can be a list of possible flavors
      # In this case, we use the first matching flavor id
      def best_flavor(quality)
        @best_flavor[quality] ||= (formats[quality] & available_flavors).first
      end

      def available_flavors
        @available_flavors ||= Array.wrap(@entry.flavor_params_ids&.split(',')&.map(&:to_i))
      end

      def flavor_assets
        @flavor_assets ||= @client.flavor_asset_service
          .get_flavor_assets_with_params(@entry.id)
          .filter_map {|fa| fa.flavor_asset.presence }
          .index_by(&:flavor_params_id)
      end

      def flavor_asset(quality)
        flavor_assets[best_flavor(quality)]
      end

      def size_by_flavor(quality)
        flavor_asset(quality)&.size_in_bytes
      end

      def updated_at_by_flavor(quality)
        Time.at(flavor_asset(quality)&.updated_at).iso8601
      rescue TypeError
        # noop
      end

      def formats
        @formats ||= Xikolo.config.kaltura['flavors']
          .symbolize_keys
          .transform_values { Array.wrap(it) }
      end
    end
  end
end
