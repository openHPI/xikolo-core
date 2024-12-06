# frozen_string_literal: true

class AddTranslationsToClassifiers < ActiveRecord::Migration[6.0]
  def change
    # Add translations to the classifiers, but allow NULLs for now
    add_column :classifiers, :translations, :jsonb, default: {}

    # Correctly fill the new field based on existing titles
    up_only do
      execute <<~SQL.squish
        UPDATE classifiers
        SET translations = CONCAT('{"#{Xikolo.config.locales['default']}": "', title, '"}')::jsonb;
      SQL
    end

    # Now that the field has been backfilled, disallow NULLs
    change_column_null :classifiers, :translations, false
  end
end
