# frozen_string_literal: true

require 'addressable'

class UnsupportedItemPresenter < ItemPresenter
  def self.build(item, section, course, user, **)
    new(item:, section:, user:, course:)
  end

  def partial_name
    'items/show_unsupported_item'
  end
end
