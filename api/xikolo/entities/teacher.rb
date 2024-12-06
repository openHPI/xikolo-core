# frozen_string_literal: true

module Xikolo
  module Entities
    class Teacher < Grape::Entity
      expose :id
      expose :name
    end
  end
end
