# frozen_string_literal: true

class FiltersController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_filter, only: [:show]

  def index
    @filters = if params[:field_names].present?
                 Filter.field_names
               elsif params[:user_test_id].present?
                 UserTest.find(params[:user_test_id]).filters
               else
                 Filter.all
               end
    respond_with(@filters)
  end

  def show
    respond_with(@filter)
  end

  private

  def set_filter
    @filter = Filter.find(params[:id])
  end
end
