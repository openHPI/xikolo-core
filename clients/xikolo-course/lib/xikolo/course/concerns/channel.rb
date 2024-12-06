# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Channel
    extend ActiveSupport::Concern

    included do
      validates :code, presence: true, uniqueness: true
      validates :name, presence: true
      validates :color, presence: true
    end
  end
end
