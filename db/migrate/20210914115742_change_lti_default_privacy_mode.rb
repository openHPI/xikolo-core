# frozen_string_literal: true

class ChangeLtiDefaultPrivacyMode < ActiveRecord::Migration[5.2]
  def change
    # Set existing values to the old implicit default, to prevent unexpected change of behavior.
    change_column_null :lti_providers, :privacy, false, 'unprotected'
  end
end
