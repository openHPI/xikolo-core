# frozen_string_literal: true

class SafeThread < Thread
  attr_reader :exception

  def initialize(*args)
    @exception = nil

    super(*args) do
      yield
    rescue Exception => e # rubocop:disable Lint/RescueException
      # warn e
      @exception = e
    end
  end

  def join!
    Thread.current.raise exception if exception

    join

    Thread.current.raise exception if exception
  end
end
