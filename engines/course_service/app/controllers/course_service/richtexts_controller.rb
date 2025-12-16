# frozen_string_literal: true

module CourseService
class RichtextsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json

  def show
    respond_with Richtext.find params[:id]
  end
end
end
