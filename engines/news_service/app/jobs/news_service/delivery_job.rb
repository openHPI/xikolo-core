# frozen_string_literal: true

module NewsService
  class DeliveryJob < ApplicationJob
    queue_as :default

    def perform(delivery_id, user)
      delivery = Delivery.find(delivery_id)

      Delivery::Send.call(delivery, user)
    end
  end
end
