# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_subscription, only: %i[show update destroy]

  def index
    subscriptions = Subscription.all
    if params[:with_question]
      include_question_for_subscription
      subscriptions.includes(question: :implicit_tags)
    end
    subscriptions = subscriptions.where index_params
    respond_with subscriptions
  end

  def show
    respond_with(@subscription)
  end

  def create
    begin
      @subscription = Subscription.where(
        user_id: subscription_params[:user_id],
        question_id: subscription_params[:question_id]
      ).first_or_create!
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    @subscription.save
    respond_with(@subscription)
  end

  def update
    @subscription.update(subscription_params)
    respond_with(@subscription)
  end

  def destroy
    @subscription.destroy
    respond_with(@subscription)
  end

  def include_question_for_subscription
    decoration_context[:with_question] = true
  end

  def decoration_context
    @decoration_context ||= {}
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def subscription_params
    params.permit :id, :user_id, :question_id
  end

  def index_params
    params.permit(:question_id, :user_id)
  end
end
