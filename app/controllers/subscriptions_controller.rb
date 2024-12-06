# frozen_string_literal: true

class SubscriptionsController < Abstract::AjaxController
  def toggle_subscription
    subscription = Xikolo::Pinboard::Subscription.find_by(
      user_id: current_user.id,
      question_id: params[:question_id]
    )
    Acfs.run
    if subscription.nil?
      Xikolo::Pinboard::Subscription.create(
        user_id: current_user.id,
        question_id: params[:question_id]
      )
    else
      subscription.delete!
    end

    head :ok
  end

  def subscription_count_text
    subscriptions = Xikolo::Pinboard::Subscription.where user_id: current_user.id
    Acfs.run
    render plain: t(:'account.preferences.show.subscription.thread_count', count: subscriptions.length)
  end

  private

  def subscription_params
    params.require(:subscription).permit(:id, :user_id, :question_id)
  end
end
