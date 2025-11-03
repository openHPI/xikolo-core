# frozen_string_literal: true

module AccountService
class FeatureDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all
end
end
