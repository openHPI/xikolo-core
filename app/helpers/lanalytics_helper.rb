# frozen_string_literal: true

# TODO: Do not use instance variables
# rubocop:disable Rails/HelperInstanceVariable

module LanalyticsHelper
  def lanalytics_data
    {
      in_app: @in_app,
    }.tap do |data|
      data[:user_id] = current_user.id unless current_user.anonymous?
      data[:build_version] = ENV['RELEASE_NUMBER'] if ENV['RELEASE_NUMBER'].present?
    end.to_json
  end
end

# rubocop:enable all
