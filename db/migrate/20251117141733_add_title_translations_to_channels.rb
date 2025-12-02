# frozen_string_literal: true

class AddTitleTranslationsToChannels < ActiveRecord::Migration[7.2]
  def change
    add_column :channels, :title_translations, :jsonb, default: {}
  end
end
