# frozen_string_literal: true

module OpenBadges
  module V2
    # WARNING: the V1 OpenBadgesController inherits from this class.
    # See: app/controllers/open_badges/v2/open_badges_controller.rb
    #
    # We don't inherit from ApplicationController, because we need none of
    # the overhead here.
    class OpenBadgesController < ActionController::Base # rubocop:disable Rails/ApplicationController
      before_action do
        head(:not_found, content_type: 'text/plain') unless Xikolo.config.open_badges['enabled']
      end

      # Issuer Profile (describing the individual or organization awarding badges)
      # Specs: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/index.html#Profile
      # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/examples/index.html#Issuer
      def issuer
        render json: {
          '@context': 'https://w3id.org/openbadges/v2',
          type: 'Issuer',
          id: openbadges_issuer_v2_url(format: :json),
          name: Xikolo.config.site_name,
          description: t(:'open_badges.issuer_description', brand: Xikolo.config.site_name, locale: issuer_locale),
          image: Xikolo.config.open_badges['issuer_image'],
          url: Xikolo.base_url.to_s,
          email: Xikolo.config.contact_email,
          publicKey: openbadges_public_key_v2_url(format: :json),
          revocationList: openbadges_revocation_list_v2_url(format: :json),
        }
      end

      # Issuer Public Key (used for verification of signed badge assertions)
      # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/index.html#CryptographicKey
      # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/examples/index.html#CryptographicKey
      # Note: the Public Key differs significantly in spec versions 1.1 and 2.0
      def public_key
        render json: {
          '@context': 'https://w3id.org/openbadges/v2',
          type: 'CryptographicKey',
          id: openbadges_public_key_v2_url(format: :json),
          owner: openbadges_issuer_v2_url(format: :json),
          publicKeyPem: Xikolo.config.open_badges['public_key'],
        }
      end

      # Revocation List (listing revoked badges with reason for revocation, currently not used)
      # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/index.html#RevocationList
      # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/examples/index.html#RevocationList
      # Note: the revocation list differs significantly in spec versions 1.1 and 2.0
      def revocation_list
        render json: {
          '@context': 'https://w3id.org/openbadges/v2',
          type: 'RevocationList',
          id: openbadges_revocation_list_v2_url(format: :json),
          issuer: openbadges_issuer_v2_url(format: :json),
          revokedAssertions: [],
        }
      end

      # Badge Class (formal description of a single achievement, i.e. the "badge blueprint")
      # Specs: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/index.html#BadgeClass
      # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0Final/examples/index.html#BadgeClass
      def badge_class
        return head(:not_found, content_type: 'text/plain') if badge_template.blank? || !course.records_released

        render json: {
          '@context': 'https://w3id.org/openbadges/v2',
          type: 'BadgeClass',
          id: course_openbadges_class_v2_url(course_id: course.course_code, format: :json),
          name: badge_name,
          description: badge_description,
          image: badge_template.file_url,
          criteria: course_url(course.course_code),
          issuer: openbadges_issuer_v2_url(format: :json),
        }
      end

      # Assertion (record of a learners achievement of the badge)
      # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/history/1.1-specification.html#Assertion
      # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/examples/#Assertion
      def assertion
        open_badge = Certificate::V2::OpenBadge.find(UUID4(params[:id]).to_s)
        render json: open_badge.assertion
      rescue ActiveRecord::RecordNotFound
        head(:not_found, content_type: 'text/plain')
      end

      private

      def course
        @course ||= Course::Course.by_identifier(params[:course_id]).take
      end

      def badge_template
        @badge_template ||= Certificate::OpenBadgeTemplate.find_by(course_id: course.id)
      end

      def badge_name
        return badge_template.name if badge_template.name.present?

        year = course.end_date&.year

        if year
          return I18n.t(
            :'open_badges.badge_class.name',
            year:,
            course_title: course.title,
            locale: badge_lang
          )
        end

        I18n.t(
          :'open_badges.badge_class.name_fallback',
          course_title: course.title,
          locale: badge_lang
        )
      end

      def badge_description
        return badge_template.description if badge_template.description.present?

        I18n.t(
          :'open_badges.badge_class.description',
          brand: Xikolo.config.site_name,
          course_title: course.title,
          locale: badge_lang
        )
      end

      def issuer_locale
        # Use english, if configured as available locale
        return :en if Xikolo.config.locales['available'].include?('en')

        # fall back to the default locale, if it provides a proper translation
        default_locale = Xikolo.config.locales['default'].to_sym
        return default_locale if I18n.exists?('open_badges.issuer_description', default_locale)

        # otherwise, still fall back to english
        :en
      end

      def badge_lang
        return course.lang.to_sym if Xikolo.config.locales['available'].include?(course.lang)

        Xikolo.config.locales['default'].to_sym
      end
    end
  end
end
