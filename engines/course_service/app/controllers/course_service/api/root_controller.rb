# frozen_string_literal: true

module CourseService
class API::RootController < ApplicationController # rubocop:disable Layout/IndentationWidth
  class NotAuthorized < RuntimeError
  end

  class RecordNotFound < RuntimeError
  end

  rescue_from NotAuthorized, with: :error_unauthorized
  rescue_from RecordNotFound, with: :error_not_found

  def error_unauthorized
    error :unauthorized
  end
end
end
