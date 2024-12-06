# frozen_string_literal: true

if Rails.env.integration? && ENV['GURKE']
  require 'webmock'

  WebMock.enable!
  WebMock.allow_net_connect!

  require 'rack/remote'

  def __clean_database
    Rails.logger.info '>>> Clean database [Account]'

    Group.where.not(name: [Group::NAME::ADMINISTRATORS, Group::NAME::ADMINISTRATORS_GDPR]).delete_all
    Grant.where.not(principal: [Group.administrators, Group.gdpr_admins]).delete_all

    Context.where.not(parent_id: nil).delete_all
    CustomField.where(required: true).delete_all
  end

  XiIntegration.hook :test_setup do
    __clean_database
  end

  begin
    __clean_database
  rescue StandardError => e
    puts e
  end

  Rack::Remote.register :test_mandatory_profile do |_params, _env, _request|
    CustomTextField.create! \
      name: 'profession',
      context: 'user',
      required: true

    nil
  end
end
