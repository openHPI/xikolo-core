# frozen_string_literal: true

if Rails.env.integration?
  require 'rack/remote'
  require 'database_cleaner'

  DatabaseCleaner.strategy = :truncation, {
    except: %w[
      ar_internal_metadata
      contexts
      custom_fields
      grants
      groups
      providers
      roles
    ],
  }

  def __clean_with_truncate
    Rails.logger.info '>>> Clean database with TRUNCATE'
    DatabaseCleaner.clean
  end

  XiIntegration.hook :test_setup do
    __clean_with_truncate
  end
end
