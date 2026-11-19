# frozen_string_literal: true

class Breadcrumbs
  def initialize
    @levels = []
  end

  def with_level(url, text)
    @levels << {url:, text:}
    self
  end

  def to_a
    @levels
  end
end
