# frozen_string_literal: true

class IconNavigationPresenter < PrivatePresenter
  attr_reader :items

  def show?
    items.any?
  end
end
