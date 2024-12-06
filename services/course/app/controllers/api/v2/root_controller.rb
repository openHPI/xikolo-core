# frozen_string_literal: true

class API::V2::RootController < API::RootController
  def api_version
    2
  end
end
