# frozen_string_literal: true

class TestGroupsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_test_group, only: [:show]

  def index
    test_groups = TestGroup.includes(:user_test)
    filter test_groups, by: :user_test_id
    respond_with(test_groups)
  end

  def show
    respond_with(@test_group)
  end

  def decoration_context
    {statistics: params[:statistics] == 'true'}
  end

  private

  def set_test_group
    @test_group = TestGroup.find(params[:id])
  end
end
