# frozen_string_literal: true

if Rails.env.integration?
  require 'database_cleaner'
  require 'webmock'
  require 'rack/remote'

  WebMock.enable!
  WebMock.allow_net_connect!

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
    AccountService::Group.where.not(name: [AccountService::Group::NAME::ADMINISTRATORS,
                                           AccountService::Group::NAME::ADMINISTRATORS_GDPR]).delete_all
    AccountService::Grant.where.not(principal: [AccountService::Group.administrators,
                                                AccountService::Group.gdpr_admins]).delete_all

    AccountService::Context.where.not(parent_id: nil).delete_all
    DatabaseCleaner.clean
  end

  XiIntegration.hook :test_setup do
    __clean_with_truncate
  end
end
