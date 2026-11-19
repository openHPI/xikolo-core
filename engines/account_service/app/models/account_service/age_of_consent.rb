# frozen_string_literal: true

module AccountService
  # The age below which registration requires the consent of a legal guardian.
  module AgeOfConsent
    YEARS = 16

    def self.underage?(born_at)
      born_at.present? && born_at.to_date > YEARS.years.ago.to_date
    end
  end
end
