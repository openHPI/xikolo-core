# frozen_string_literal: true

class UserTestsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_user_test, only: %i[show update destroy]

  def index
    user_tests = UserTest.order('start_date DESC', 'end_date DESC').all
    user_tests.where! identifier: params[:identifier] if params[:identifier]
    user_tests.includes!(:metrics)
    respond_with user_tests
  end

  def show
    if params[:export] == 'true'
      decoration_context[:export] = true
      decoration_context[:metric_name] = params[:metric_name]
    end
    decoration_context[:statistics] = params[:statistics] == 'true'
    respond_with @user_test
  end

  def create
    test = UserTest.create!(test_params)
    test.add_test_groups test_groups
    test.add_metrics params[:metrics] if params[:metrics]
    test.add_filters params[:filter_strings] if params[:filter_strings]
    test.compute_statistics
    respond_with test
  end

  def update
    @user_test.update(test_params)
    @user_test.add_metrics params[:metrics] if params[:metrics]
    @user_test.add_filters params[:filter_strings] if params[:filter_strings]
    respond_with @user_test
  end

  def destroy
    @user_test.destroy
    respond_with @user_test
  end

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def set_user_test
    @user_test = UserTest.find(params[:id])
  end

  def test_params
    params.delete_if {|k, v| (k == 'course_id') && v.blank? }
    params.permit(:name, :identifier, :description, :start_date, :end_date,
      :max_participants, :course_id, :round_robin, metrics: [])
  end

  def test_groups
    p = params.permit(test_groups: [:name, :description, {flippers: []}])

    Array(p[:test_groups])
  end
end
