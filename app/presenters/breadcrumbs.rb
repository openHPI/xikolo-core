# frozen_string_literal: true

class Breadcrumbs
  def initialize
    @levels = {}
  end

  def with_level(url, text)
    @levels[url] = text
    self
  end

  def each_level(&)
    @levels.each(&)
  end
end
