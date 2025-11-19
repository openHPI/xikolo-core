# frozen_string_literal: true

module Global
  class Table < ApplicationComponent
    # @param rows [Array<Hash>] table rows as hashes
    # @param headers [Array<String>] table headers
    # @param title [String, nil] optional table title
    # @param caption [String, nil] optional table caption
    def initialize(rows:, headers: [], title: nil, caption: nil)
      @rows = rows
      @headers = headers
      @title = title
      @column_blocks = {}
      @caption = caption
    end

    attr_reader :rows, :headers, :title, :column_blocks, :caption

    def column(key, &block)
      @column_blocks[key.to_sym] = block if block_given?
    end

    private

    def before_render
      content if content?
    end

    def value_for(row, key)
      block = @column_blocks[key.to_sym]
      block ? view_context.capture(row, &block) : row[key].to_s
    end
  end
end
