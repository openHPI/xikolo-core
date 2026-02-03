# frozen_string_literal: true

module AccountService
class TokenSession < AccountService::Session # rubocop:disable Layout/IndentationWidth
  attr_accessor :token

  def to_param
    "token=#{token}"
  end

  def access!; end
end
end
