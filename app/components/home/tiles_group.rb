# frozen_string_literal: true

module Home
  class TilesGroup < ApplicationComponent
    def initialize(title: nil)
      @title = title
    end

    renders_many :tiles, Tile
  end
end
