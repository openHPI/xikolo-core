# frozen_string_literal: true

class CoursesDecorator < Draper::CollectionDecorator
  def to_msgpack(opts)
    payload = ::Mnemosyne.trace('app.decorator.as_json') { as_json(opts) }

    ::Mnemosyne.trace('app.decorator.to_msgpack') { payload.to_msgpack }
  end
end
