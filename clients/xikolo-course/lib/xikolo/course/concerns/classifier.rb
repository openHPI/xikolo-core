# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Classifier
    extend ActiveSupport::Concern

    included do
      validates :title, presence: true
      validates :cluster, presence: true
    end
  end
end
