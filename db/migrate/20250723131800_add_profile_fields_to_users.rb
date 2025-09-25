# frozen_string_literal: true

class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def up
    create_enum :gender, %w[male female diverse undisclosed]
    create_enum :user_category, %w[school_student university_student teacher other]
    create_enum :state, %w[BW BY BE BB HB HH HE MV NI NW RP SL SN ST SH TH]

    change_table :users, bulk: true do |t|
      t.string :country
      t.enum :state, enum_type: :state
      t.string :city
      t.enum :gender, enum_type: :gender
      t.enum :status, enum_type: :user_category
    end
  end

  def down
    change_table :users, bulk: true do |t|
      t.remove :country, :state, :city, :gender, :status
    end

    drop_enum :state
    drop_enum :gender
    drop_enum :user_category
  end
end
