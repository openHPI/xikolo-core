# frozen_string_literal: true

MissionControl::Jobs.base_controller_class = 'ActionController::Base'
MissionControl::Jobs.http_basic_auth_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ADMIN_DASHBOARDS_PASSWORD_SET', !Rails.env.local?))
# When no user/password is set in production no access will be possible.
MissionControl::Jobs.http_basic_auth_user = ENV.fetch('ADMIN_DASHBOARDS_USER', nil)
MissionControl::Jobs.http_basic_auth_password = ENV.fetch('ADMIN_DASHBOARDS_PASSWORD', nil)
