# frozen_string_literal: true

module UUIDHelper
  def short_uuid(id)
    UUID4(id).to_param
  end
end
