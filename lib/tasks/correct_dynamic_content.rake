# frozen_string_literal: true

namespace :dynamic_content do
  desc 'Remove invalid dynamic content from certificates'
  task remove_invalid_content: :environment do
    puts 'Starting task...'

    certificates = Certificate::Template.all

    total_processed = 0
    failed_records = []

    certificates.in_batches(of: 200).each_record do |template|
      modified_content = template.dynamic_content
        .gsub('id="Dynamic data"', 'id="dynamic-data"')
        .gsub(/\s*baseProfile="basic"/, '') # Removes the baseProfile="basic" including leading whitespace
        .gsub('font=', 'font-family=')
        .gsub('fontfamily=', 'font-family=')
        .gsub('strokewidth=', 'stroke-width=')
        .gsub('fontsize=', 'font-size=')
        .gsub('textanchor=', 'text-anchor=')
        .gsub('text-anchor="left"', 'text-anchor="start"')

      # Skip this iteration if no changes were made
      next if modified_content == template.dynamic_content

      begin
        template.update!(dynamic_content: modified_content.strip)
        total_processed += 1
      rescue => e
        puts "Failed to update template #{template.id}: #{e.message}"
        failed_records << template.id
      end
    end

    # Summary log
    puts "#{total_processed} records processed."
    if failed_records.any?
      puts "Failed to update templates with IDs: #{failed_records.join(', ')}"
    else
      puts 'All templates were successfully updated.'
    end
  end
end
