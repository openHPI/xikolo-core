# frozen_string_literal: true

namespace :account do
  desc 'Backfill gender, country, city from custom_field_values into users'
  task migrate_custom_fields: :environment do
    gender_field_id  = '1c455b65-4507-48c8-a5ed-537c12d2c715'
    city_field_id    = '96ad7534-c630-40ae-8482-9c73712e0da2'
    country_field_id = '4404529b-90b3-4b27-b093-1702605ac6ae'

    def map_gender(value)
      {
        'male'     => 'male',
        'female'   => 'female',
        'other'    => 'diverse',
        'not_set'  => 'undisclosed',
      }[value]
    end

    def map_country(value)
      return nil if value == 'not_set'

      value.to_s.upcase # adjust if you have a strict enum mapping
    end

    total = CustomFieldValue.where(custom_field_id: [gender_field_id, city_field_id, country_field_id]).count
    puts "Migrating #{total} custom field values in batches of 1000..."

    CustomFieldValue.where(custom_field_id: [gender_field_id, city_field_id, country_field_id]).find_each do |cfv|
      user = User.find_by(id: cfv.context_id)
      next unless user

      value = cfv.values&.first
      next if value.blank?

      updates = {}

      case cfv.custom_field_id
        when gender_field_id
          updates[:gender] = map_gender(value)
        when country_field_id
          updates[:country] = map_country(value)
        when city_field_id
          updates[:city] = value
      end

      # update_column skips validations
      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:gender, updates[:gender]) if updates.key?(:gender) && user.gender.blank?
      user.update_column(:country, updates[:country]) if updates.key?(:country) && user.country.blank?
      user.update_column(:city, updates[:city]) if updates.key?(:city) && user.city.blank?
      # rubocop:enable Rails/SkipsModelValidations
    end

    puts 'Migration completed!'
  end
end
