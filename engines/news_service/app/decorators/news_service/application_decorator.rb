# frozen_string_literal: true

module NewsService
class ApplicationDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  # Draper will use the main apps helper by default.
  def h
    super.news_service
  end
end
end
