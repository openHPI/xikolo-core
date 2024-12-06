# frozen_string_literal: true

class MultipleNewsDecorator < Draper::CollectionDecorator
  # This class is temporarily needed to experiment with Msgpack responses for
  # collections of news.
  def to_msgpack(opts)
    as_json(opts).to_msgpack
  end
end
