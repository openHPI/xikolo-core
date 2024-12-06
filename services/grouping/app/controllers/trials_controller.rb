# frozen_string_literal: true

class TrialsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_trial, only: %i[show update destroy]

  def index
    trials = Trial.all
    filter trials, by: :user_id

    if params[:identifier].present?
      trials = filter_by_identifier trials, params[:identifier]
    end

    if params[:group_by_day] == 'true'
      trials = trials.group_by_day(:created_at).count
    end

    respond_with(trials)
  end

  def show
    respond_with(@trial)
  end

  def update
    @trial.update!(trial_params)
    head :no_content
  end

  def destroy
    @trial.destroy
    respond_with(@trial)
  end

  private

  def filter_by_identifier(trials, identifier)
    user_test = UserTest.find_by(identifier:)
    if params[:active] == 'true' && user_test && !user_test.active?
      user_test = nil
    end

    if user_test
      trials.where(user_test_id: user_test.id)
    else
      Trial.none
    end
  end

  def set_trial
    @trial = Trial.find(params[:id])
  end

  def trial_params
    params.permit(:id, :finished, :waiting, :result, :user_test_id)
  end
end
