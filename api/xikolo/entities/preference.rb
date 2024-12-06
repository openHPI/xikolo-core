# frozen_string_literal: true

module Xikolo
  module Entities
    class Preference < Grape::Entity
      expose :id
      expose :value
    end
  end
end
