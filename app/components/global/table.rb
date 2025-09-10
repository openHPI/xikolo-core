# frozen_string_literal: true

module Global
  class Table < ApplicationComponent
    # @param data [Array<Hash>] table rows as hashes
    # @param headers [Array<String>] table headers
    # @param title [String, nil] optional table title
    def initialize(data:, headers: [], title: nil)
      @data = data
      @headers = headers
      @title = title
    end

    attr_reader :data, :headers, :title
  end
end
