# frozen_string_literal: true

module CourseService
class API::V2::RootController < API::RootController # rubocop:disable Layout/IndentationWidth
  def api_version
    2
  end
end
end
