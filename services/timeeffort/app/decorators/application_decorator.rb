# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  # Draper will use the main apps helper by default.
  def h
    super.timeeffort_service
  end
end
