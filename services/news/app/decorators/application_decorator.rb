# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  def to_msgpack(opts)
    as_json(opts).to_msgpack
  end
end
