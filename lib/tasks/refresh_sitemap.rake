# frozen_string_literal: true

namespace :sitemap do
  Rake::Task['sitemap:create'].enhance do
    Rake::Task['sitemap:upload_to_s3'].invoke
  end

  desc 'Upload the sitemap to S3 bucket'
  task upload_to_s3: :environment do
    puts 'Starting sitemap upload to S3...'

    bucket = Xikolo::S3.bucket_for(:sitemaps)

    if Dir['tmp/sitemaps/*.xml.gz'].empty?
      puts 'No sitemap file was found!'
    end

    Dir['tmp/sitemaps/*.xml.gz'].each do |path|
      filename = File.basename(path)
      file = Rails.root.join(path)

      begin
        File.open(file) do |f|
          bucket.put_object(
            key: File.join('sitemaps', filename),
            body: f,
            acl: 'public-read'
          )
        end
        puts "Saved #{filename} to S3"
      rescue Aws::S3::Errors::ServiceError => e
        Mnemosyne.attach_error(e)
        Sentry.capture_exception(e)
        puts "#{filename} was not saved"
      end
    end
  end
end
