# frozen_string_literal: true

class AddRequiredSectionIdsToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :required_section_ids, :uuid, array: true, default: [], null: false
  end
end
