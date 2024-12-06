# frozen_string_literal: true

class Presenter
  extend Forwardable

  def initialize(params)
    params&.each_pair do |attribute, value|
      send :"#{attribute}=", value
    end
  end
end
