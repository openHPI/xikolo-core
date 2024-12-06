# frozen_string_literal: true

class Time
  def to_msgpack(*)
    as_json.to_msgpack(*)
  end
end
