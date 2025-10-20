# frozen_string_literal: true

module TimeeffortService
class RootController < ApplicationController # rubocop:disable Layout/IndentationWidth
  def index
    render json: {
      items_url: items_rfc6570,
      item_url: item_rfc6570,
      item_overwritten_time_effort_url: item_overwritten_time_effort_rfc6570,
    }
  end
end
end
