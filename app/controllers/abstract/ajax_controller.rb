# frozen_string_literal: true

module Abstract
  ##
  # A base class for all controllers handling AJAX requests
  class AjaxController < ::ApplicationController
    rescue_from Status::Unauthorized do
      render status: :forbidden, json: {errors: 'forbidden'}
    end

    def ensure_logged_in
      return true if current_user.logged_in?

      head :forbidden
    end
  end
end
