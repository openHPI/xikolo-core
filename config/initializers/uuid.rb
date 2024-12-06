# frozen_string_literal: true

require 'uuid4'

module UUID4Param
  def to_param
    to_s(format: :base62)
  end
end

UUID4.include UUID4Param
