# frozen_string_literal: true

class ConsentPresenter
  # @param treatment [Restify::Resource]
  def self.from_treatment(treatment)
    consent = {
      name: treatment['name'],
      required: treatment['required'],
      consented: treatment['required'] || nil,
      external_consent_url: treatment.dig('consent_manager', 'consent_url').presence,
    }
    new(consent.stringify_keys)
  end

  # @param consent [Restify::Resource|Hash]
  #   The resource from the service or a Hash representation (see `.from_treatment`).
  def initialize(consent)
    @consent = consent
  end

  def external_url
    @consent['external_consent_url']
  end

  def name
    @consent['name']
  end

  def consented?
    @consent['consented']
  end

  def consented_at
    return if @consent['consented_at'].blank?

    @consented_at ||= Time.zone.parse @consent['consented_at']
  end

  def consented_at_msg
    return unless consented_at

    msg_key = if consented?
                :'account.shared.consent.profile.consented_at'
              else
                :'account.shared.consent.profile.consent_declined_at'
              end

    I18n.t(
      msg_key,
      date: I18n.l(consented_at, format: :short_datetime)
    )
  end

  def required?
    @consent['required']
  end

  def label
    I18n.t("account.shared.consent.#{name}.label")
  end

  # Presentational HTML is allowed in this locale.
  def text
    I18n.t("account.shared.consent.#{name}.text", brand: Xikolo.config.site_name).html_safe
  end
  # rubocop:enable all

  def as_json(opts = {})
    consent = {
      name:,
      consented: consented?,
    }
    consent[:consented_at_msg] = consented_at_msg
    consent.as_json(opts)
  end
end
