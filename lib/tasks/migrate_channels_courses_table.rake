# frozen_string_literal: true

namespace :courses do
  desc 'Migrate existing course channel_id to ChannelsCourses association'
  task migrate_to_channels_courses: :environment do
    puts 'Starting migration of course channels...'

    migrated_count = 0
    error_count = 0

    puts "\n\nMigrating CourseService::Course records..."
    CourseService::Course.find_each do |course|
      next if course.channel_id.blank?

      begin
        CourseService::ChannelsCourse.find_or_create_by!(
          course: course,
          channel_id: course.channel_id
        )
        migrated_count += 1
        print '.' if migrated_count % 100 == 0
      rescue ActiveRecord::RecordInvalid => e
        puts "\nError migrating CourseService::Course #{course.id}: #{e.message}"
        error_count += 1
      rescue => e
        puts "\nUnexpected error for CourseService::Course #{course.id}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n\n#{'=' * 50}"
    puts 'Migration complete!'
    puts "Migrated: #{migrated_count} records"
    puts "Errors: #{error_count} records"
    puts '=' * 50
  end
end
