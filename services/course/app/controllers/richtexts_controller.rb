# frozen_string_literal: true

class RichtextsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json

  def show
    respond_with Richtext.find params[:id]
  end
end
