# frozen_string_literal: true

module PinboardService
class CourseSubscriptionsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  before_action :set_course_subscription, only: %i[show update destroy]

  def index
    course_subscriptions = CourseSubscription.where index_params
    respond_with course_subscriptions
  end

  def show
    respond_with(@course_subscription)
  end

  def create
    @course_subscription = CourseSubscription.create_or_find_by!(
      user_id: course_subscription_params[:user_id],
      course_id: course_subscription_params[:course_id]
    )

    respond_with(@course_subscription)
  end

  def update
    @course_subscription.update(course_subscription_params)
    respond_with(@course_subscription)
  end

  def destroy
    @course_subscription.destroy
    respond_with(@course_subscription)
  end

  private

  def set_course_subscription
    @course_subscription = CourseSubscription.find(params[:id])
  end

  def course_subscription_params
    params.permit :id, :user_id, :course_id
  end

  def index_params
    params.permit(:course_id, :user_id)
  end
end
end
