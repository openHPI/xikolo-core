# frozen_string_literal: true

module NotificationService
module Resources # rubocop:disable Layout/IndentationWidth
  class Features
    def initialize(hash)
      @hash = hash
    end

    def key?(name)
      @hash.key? name
    end
  end
end
end
