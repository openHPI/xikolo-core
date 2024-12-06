# frozen_string_literal: true

require 'multi_process'

class BroadcastReceiver < MultiProcess::Receiver
  def initialize(*args)
    super
    @subscribers = []
  end

  def <<(subscriber)
    @subscribers << subscriber
  end

  protected

  def received(process, name, line)
    @subscribers.each do |subscriber|
      subscriber.send(:received, process, name, line)
    end
  end
end
