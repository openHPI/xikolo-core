# frozen_string_literal: true

class API::RootController < ApplicationController
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
