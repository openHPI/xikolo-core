# frozen_string_literal: true

module UUIDHelper
  def short_uuid(id)
    UUID(id).to_s(format: :base62)
  end
end

Gurke.world.include(UUIDHelper)
