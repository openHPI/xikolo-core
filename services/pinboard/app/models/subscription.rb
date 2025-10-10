# frozen_string_literal: true

class Subscription < ApplicationRecord
  self.table_name = :subscriptions

  belongs_to :question

  default_scope { order created_at: :desc }

  after_commit(on: :create) { notify :create }
  after_commit(on: :destroy) { notify :destroy }

  def notify(action_sym)
    Msgr.publish(decorate.as_json, to: "xikolo.pinboard.subscription.#{action_sym.to_s.downcase}")
  end
end
