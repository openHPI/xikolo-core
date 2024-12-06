# frozen_string_literal: true

module User
  class SubscriptionsController < ApplicationController
    before_action :ensure_logged_in

    def destroy
      subscription = Xikolo::Pinboard::Subscription.find_by!(
        user_id: current_user.id,
        question_id: params[:question_id]
      )
      Acfs.run

      if subscription.delete
        add_flash_message :success, t(:'flash.success.subscription_canceled')
      else
        add_flash_message :error, t(:'flash.error.subscription_not_canceled')
      end

      redirect_to preferences_path
    rescue Acfs::ResourceNotFound
      # It's already gone
      redirect_to preferences_path
    end
  end
end
