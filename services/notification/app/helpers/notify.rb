# frozen_string_literal: true

module Notify
  def notify_all(receivers, key, payload)
    receivers.each do |receiver|
      notify receiver, key, payload
    end
  end

  def notify(receiver, key, payload)
    Msgr.publish(
      {key:, receiver_id: receiver, payload:},
      to: 'xikolo.notification.notify'
    )
  end
end
