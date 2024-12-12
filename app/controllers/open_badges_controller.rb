# frozen_string_literal: true

class OpenBadgesController < OpenBadges::OpenBadgesController
  # Issuer Profile (describing the individual or organization awarding badges)
  # Specs: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/history/1.1-specification.html#Issuer
  # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/examples/index.html#Issuer
  def issuer
    render json: {
      '@context': 'https://w3id.org/openbadges/v1',
      type: 'Issuer',
      id: openbadges_issuer_url(format: :json),
      name: Xikolo.config.site_name,
      description: I18n.t(:'open_badges.issuer_description', brand: Xikolo.config.site_name, locale: issuer_locale),
      image: Xikolo.config.open_badges['issuer_image'],
      url: Xikolo.base_url.to_s,
      email: Xikolo.config.contact_email,
      publicKey: openbadges_public_key_url(format: :json),
      revocationList: openbadges_revocation_list_url(format: :json),
    }
  end

  # Issuer Public Key (used for verification of signed badge assertions)
  # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#CryptographicKey
  # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/examples/index.html#CryptographicKey
  # Note: the Public Key differs significantly in spec versions 1.1 and 2.0
  def public_key
    render plain: Xikolo.config.open_badges['public_key']
  end

  # Revocation List (listing revoked badges with reason for revocation, currently not used)
  # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#RevocationList
  # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#RevocationList
  # Note: the revocation list differs significantly in spec versions 1.1 and 2.0
  def revocation_list
    render json: []
  end

  # Badge Class (formal description of a single achievement, i.e. the "badge blueprint")
  # Specs: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/history/1.1-specification.html#BadgeClass
  # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/examples/index.html#BadgeClass
  def badge_class
    return head(:not_found, content_type: 'text/plain') if badge_template.blank? || !course['records_released']

    render json: {
      '@context': 'https://w3id.org/openbadges/v1',
      type: 'BadgeClass',
      id: course_badge_class_url(course_id: course.course_code, format: :json),
      name: badge_name,
      description: badge_description,
      image: badge_template.file_url,
      criteria: course_url(course.course_code),
      issuer: openbadges_issuer_url(format: :json),
    }
  end

  # Assertion (record of a learners achievement of the badge)
  # Spec: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/history/1.1-specification.html#Assertion
  # Example: https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/examples/#Assertion
  def assertion
    open_badge = Certificate::OpenBadge.find(UUID4(params[:id]).to_s)
    render json: open_badge.assertion
  rescue ActiveRecord::RecordNotFound
    head(:not_found, content_type: 'text/plain')
  end
end
