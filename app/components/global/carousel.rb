# frozen_string_literal: true

module Global
  # Horizontally scrolling list paged by previous/next buttons beside it.
  #
  # - `:md` shows one item per page on small screens, two from `md` and three
  #   from `lg`. With fewer items than fit on a page, the items grow to fill
  #   the row.
  # - `:sm` fits more, smaller items: one per page on small screens, three from
  #   `md` and four from `lg`. The items keep their width when there are few.
  class Carousel < ApplicationComponent
    TRACK_CLASSES = {
      md: 'gap-8 lg:gap-16',
      sm: 'gap-8',
    }.freeze

    ITEM_CLASSES = {
      md: 'grow basis-full md:basis-[calc((100%-2rem)/2)] lg:basis-[calc((100%-8rem)/3)]',
      sm: 'basis-full md:basis-[calc((100%-4rem)/3)] lg:basis-[calc((100%-6rem)/4)]',
    }.freeze

    renders_many :items

    # @param label [String] accessible name of the carousel region
    # @param size [Symbol] item size, `:md` or `:sm`
    def initialize(label:, size: :md)
      @label = label
      @size = size.to_sym

      raise ArgumentError.new("Unknown size: #{size}") unless ITEM_CLASSES.key?(@size)
    end

    def render?
      items?
    end

    private

    def track_classes
      TRACK_CLASSES.fetch(@size)
    end

    def item_classes
      ITEM_CLASSES.fetch(@size)
    end
  end
end
