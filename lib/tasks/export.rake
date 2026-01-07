# frozen_string_literal: true

require 'csv'

namespace :export do
  desc <<-DOC.gsub(/\s+/, ' ')
  Export all items with course code and section titles in order to a CSV file. Write to OUT=/path/to/output/file.csv
  DOC
  task all_items: :environment do
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @filename = ENV['OUT'] || '/tmp/export_all_items.csv'

    CSV.open(@filename, 'w') do |csv_file|
      csv_file << %w[course_code section_pos section_title item_pos item_title]

      CourseService::Course.order(:course_code).each do |course|
        course.sections.each do |section|
          section.items.each do |item|
            csv_file << [
              course.course_code,
              section.position,
              section.title,
              item.position,
              item.title,
            ]
          end

          csv_file.flush
        end
      end
    end
  end
end
