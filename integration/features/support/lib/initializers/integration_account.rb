# frozen_string_literal: true

if Rails.env.integration? && ENV['GURKE']
  require 'webmock'
  require 'rack/remote'

  WebMock.enable!
  WebMock.allow_net_connect!

  def __clean_database
    Rails.logger.info '>>> Clean database [Account]'

    AccountService::Group.where.not(name: [AccountService::Group::NAME::ADMINISTRATORS,
                                           AccountService::Group::NAME::ADMINISTRATORS_GDPR]).delete_all
    AccountService::Grant.where.not(principal: [AccountService::Group.administrators,
                                                AccountService::Group.gdpr_admins]).delete_all

    AccountService::Context.where.not(parent_id: nil).delete_all
  end

  XiIntegration.hook :test_setup do
    __clean_database
  end

  begin
    __clean_database
  rescue StandardError => e
    puts e
  end
end
