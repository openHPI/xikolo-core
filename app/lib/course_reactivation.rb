# frozen_string_literal: true

module CourseReactivation
  class << self
    def config(key)
      Xikolo.config.course_reactivation[key]
    end

    def enabled?
      # Course reactivations can only be booked using vouchers;
      # require this feature to be enabled.
      Xikolo.config.voucher['enabled'] &&
        Xikolo.config.course_reactivation.present?
    end

    def store_url
      configured_url = config 'store_url'

      # If the config is a string, that's our URL and we're done
      return configured_url if configured_url.respond_to? :to_str

      # Otherwise, we assume one URL per locale, and fall back to English
      configured_url[I18n.locale.to_s] || configured_url['en']
    end
  end
end
