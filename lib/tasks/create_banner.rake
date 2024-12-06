# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'addressable/uri'

namespace :banner do
  desc 'Add a banner to be displayed, e.g. on the course list'
  task create: :environment do
    ##
    # Download the banner file from remote
    #
    $stdout.puts 'Please enter the banner URL ("https://dev.xikolo.de/youtrack/api/files/the-banner"):'
    url = $stdin.gets.strip

    $stdout.puts 'Please enter the banner filename ("banner.png"):'
    filename = $stdin.gets.strip

    # Store file in temporary directory to be able to rename it.
    tmp_dir = Rails.root.join('tmp')
    FileUtils.mkpath tmp_dir
    filepath = File.join(tmp_dir, filename)
    File.binwrite(filepath, URI.parse(url).open(&:read))

    ##
    # Banner record configuration
    #
    $stdout.puts 'Please enter the UTC publishing date ("24-12-2021 09:15") or skip ([Enter], default: now):'
    publish_input = $stdin.gets.strip
    if publish_input.present?
      publish_at = DateTime.strptime(publish_input, '%d-%m-%Y %H:%M').utc.iso8601
    end

    $stdout.puts 'Please enter the UTC expiry date ("24-12-2021 09:15") or skip ([Enter], default: none):'
    expire_input = $stdin.gets.strip
    if expire_input.present?
      expire_at = DateTime.strptime(expire_input, '%d-%m-%Y %H:%M').utc.iso8601
    end

    $stdout.puts 'Please enter the banner alt text ("Now 20 million enrollments!"):'
    alt_text = $stdin.gets.strip

    $stdout.puts 'Please enter the banner link URL ("https://www.example.com") or skip ([Enter]):'
    link_url_input = $stdin.gets.strip
    if link_url_input.present?
      link_url = Addressable::URI.parse(link_url_input).to_s
    end

    if link_url.present?
      $stdout.puts 'Please enter the banner link target ("self", "blank") or skip ([Enter], default: "self"):'
      link_target_input = $stdin.gets.strip
      link_target = %w[self blank].include?(link_target_input) ? link_target_input : 'self'
    end

    ##
    # Upload the banner to S3
    #
    puts 'Starting the banner upload to S3...'
    begin
      uploaded_file = File.open(filepath, 'rb') do |f|
        Banner.upload!(f)
      end

      puts 'Saved the banner to S3.'
    rescue Aws::S3::Errors::ServiceError => e
      puts 'The banner could not be uploaded.'
      raise e
    ensure
      FileUtils.rmtree tmp_dir
    end

    ##
    # Create the corresponding banner record
    #
    puts 'Creating the banner record...'
    begin
      Banner.create!(
        file_uri: uploaded_file.storage_uri,
        alt_text:,
        publish_at:,
        expire_at:,
        link_url:,
        link_target:
      )

      puts 'Created the banner record. Please verify.'
    rescue ActiveRecord::RecordInvalid => e
      # Remove the corresponding (already uploaded) S3 file.
      S3FileDeletionJob.perform_later(uploaded_file.storage_uri)

      puts "The banner record could not be created. Error: #{e}"
    end
  end
end
