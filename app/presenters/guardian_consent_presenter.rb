# frozen_string_literal: true

##
# The guardian consent is not a treatment, but it is listed with them on the
# profile. Only the texts differ, as those are derived from a treatment name.
class GuardianConsentPresenter < ConsentPresenter
  def label
    I18n.t(:'account.shared.guardian_consent.label')
  end

  # Presentational HTML is allowed in this locale.
  def text
    I18n.t(:'account.shared.guardian_consent.text').html_safe
  end
end
