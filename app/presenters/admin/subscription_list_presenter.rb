# frozen_string_literal: true

class Admin::SubscriptionListPresenter
  extend Forwardable

  def initialize(subscriptions)
    @subscriptions = subscriptions
  end

  def_delegator :@subscriptions, :each

  def pagination
    RestifyPaginationCollection.new(@subscriptions)
  end
end
