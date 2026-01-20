# frozen_string_literal: true

require_relative '../../integration/features/support/minio'

namespace :local_s3 do
  task configure: :environment do
    # Copy default configuration to ~/.xikolo.development.yml (if it
    # does not already exist)
    if !File.exist? File.expand_path('~/.xikolo.development.yml')
      FileUtils.copy_file(
        'integration/features/support/lib/xikolo.development.yml',
        File.expand_path('~/.xikolo.development.yml')
      )
      puts <<~MSG
        Copied default s3 configuration to ~/.xikolo.development.yml'
        If minio is configured differently (e.g. another endpoint/
        credentials/buckets...), adjust the file accordingly.
      MSG
    elsif FileUtils.identical?(
      'integration/features/support/lib/xikolo.development.yml',
      File.expand_path('~/.xikolo.development.yml')
    )
      puts <<~MSG
        Found the default s3 configuration under ~/.xikolo.development.yml
        If minio is configured differently (e.g. another endpoint/
        credentials/buckets...), adjust the file accordingly.
      MSG
    else
      puts <<~MSG
        Found another than the default s3 configuration under
        ~/.xikolo.development.yml. If you want to use the default s3
        configuration, delete the file and run the rake task again.
      MSG
    end

    # Load environment-specific configuration
    Xikolo::Config.add_config_location '/etc/xikolo.development.yml'
    Xikolo::Config.add_config_location File.expand_path('~/.xikolo.development.yml') if ENV.key? 'HOME'

    # Create buckets with needed policies:
    Minio.setup

    puts 'Successfully set up minio'
  end

  task delete: :environment do
    # Load environment-specific configuration
    Xikolo::Config.add_config_location '/etc/xikolo.development.yml'
    Xikolo::Config.add_config_location File.expand_path('~/.xikolo.development.yml') if ENV.key? 'HOME'

    # Remove all buckets
    Minio.delete_all
    puts 'Successfully cleared all buckets'
  end
end
