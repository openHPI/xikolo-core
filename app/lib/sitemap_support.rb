# frozen_string_literal: true

module SitemapSupport
  class << self
    def language_alternates(link)
      available_translations.map do |platform_locale, sitemap_locale|
        {
          href: Xikolo.base_url.join("#{link}?locale=#{platform_locale}").to_s,
          lang: sitemap_locale,
        }
      end
    end

    def video_sitemap(stream, title, description)
      {
        title:,
        description:,
        content_loc: Rails.application.routes.url_helpers.stream_download_url(
          stream_id: UUID4(stream.id).to_param,
          quality: stream.hd_download_url.present? ? 'hd' : 'sd',
          host: Xikolo.config.base_url.site
        ),
        thumbnail_loc: stream.poster,
        duration: stream.duration,
      }
    end

    def video_description(item)
      item['public_description']&.strip
    end

    def available_translations
      @available_translations ||= (Xikolo.config.locales['available'] - %w[en]).to_h do |platform_locale|
        locale = platform_locale.to_sym
        [locale, locale_map[locale]]
      end
    end

    # A hash for looking up the name of a locale in the sitemap standard, given only
    # a locale name as used on the platform
    def locale_map
      @locale_map ||= {
        cn: :zh,
      }.tap do |locale_map|
        # By default, just return the locale as used on the platform
        locale_map.default_proc = proc do |hash, key|
          hash[key] = key
        end
      end
    end
  end
end
