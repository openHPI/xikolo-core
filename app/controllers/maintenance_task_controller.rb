# frozen_string_literal: true

class MaintenanceTaskController < ApplicationController
  password_protected = if ENV.key?('ADMIN_DASHBOARDS_PASSWORD_SET')
                         ActiveModel::Type::Boolean.new.cast(ENV['ADMIN_DASHBOARDS_PASSWORD_SET'])
                       else
                         !Rails.env.local?
                       end

  if password_protected
    http_basic_authenticate_with name: ENV.fetch('ADMIN_DASHBOARDS_USER'),
      password: ENV.fetch('ADMIN_DASHBOARDS_PASSWORD')
  end
end
