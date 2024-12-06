# frozen_string_literal: true

class CreateOffers < ActiveRecord::Migration[6.0]
  def change
    create_enum :payment_frequency, %w[one_time weekly monthly quarterly half_yearly by_semester yearly other]
    create_enum :offer_category, %w[course certificate complete]

    create_table 'course_offers', id: :uuid do |t|
      t.string 'price_currency', null: false, default: 'EUR'
      t.enum 'payment_frequency', enum_type: :payment_frequency, null: false, default: 'one_time'
      t.enum 'category', enum_type: :offer_category, null: false, default: 'course'
      t.integer 'price', default: 0, null: false
      t.references :course, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
