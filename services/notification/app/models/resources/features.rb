# frozen_string_literal: true

module Resources
  class Features
    def initialize(hash)
      @hash = hash
    end

    def key?(name)
      @hash.key? name
    end
  end
end
