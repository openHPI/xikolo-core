# frozen_string_literal: true

module AccountService
  module CodeOceanClient
    class << self
      def connection
        @connection ||= Faraday.new(
          url: ENV.fetch('CODE_OCEAN_API_URL', nil)
        ) do |f|
          f.request :authorization, 'Bearer', ENV.fetch('XIKOLO_WEB_API')
          f.response :json
          f.response :raise_error
          f.adapter Faraday.default_adapter
        end
      end

      def delete_user(user_id)
        connection.delete("/api/internal/users/#{user_id}")
      end
    end
  end
end
