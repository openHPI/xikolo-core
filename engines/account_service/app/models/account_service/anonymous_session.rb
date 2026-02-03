# frozen_string_literal: true

module AccountService
class AnonymousSession < AccountService::Session # rubocop:disable Layout/IndentationWidth
  def to_param
    'anonymous'
  end

  def interrupt?
    false
  end

  def interrupts
    []
  end

  def access!; end
end
end
