# lib/tasks/migrate_career_status.rake
# frozen_string_literal: true

namespace :account do
  desc 'Migrate career_status CustomFieldValues to users.status in batches'
  task migrate_career_status: :environment do
    field_id = 'e1e75a25-f617-4ba4-9262-b23f7529e089'
    batch_size = 1000

    def map_status(value)
      mapping = {
        'student' => 'university_student',
        'teacher' => 'teacher',
      }

      mapping[value] || 'other'
    end

    total_records = AccountService::CustomFieldValue.where(custom_field_id: field_id).count
    puts "Migrating #{total_records} career_status values in batches of #{batch_size}..."

    processed = 0

    AccountService::CustomFieldValue.where(custom_field_id: field_id)
      .in_batches(of: batch_size)
      .each_with_index do |batch, index|
      puts "Processing batch ##{index + 1}..."

      batch.each do |cfv|
        user = AccountService::User.find_by(id: cfv.context_id)
        next unless user

        value = cfv.values&.first
        next if value.blank?

        mapped = map_status(value)
        next if mapped.blank?

        # rubocop:disable Rails/SkipsModelValidations
        user.update_column(:status, mapped) if user.status.blank?
        # rubocop:enable Rails/SkipsModelValidations
      end

      processed += batch.size
      puts " → Processed #{processed}/#{total_records}"
    end

    puts 'Career status migration completed!'
  end
end
