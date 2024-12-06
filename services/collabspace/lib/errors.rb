# frozen_string_literal: true

module Errors
  class Problem < StandardError
    attr_reader :reason

    def initialize(reason)
      super
      @reason = reason
    end

    def as_json(opts)
      {errors: {base: [reason]}}.as_json(opts)
    end
  end

  class InvalidUpload < Problem
    def initialize(reason = 'could_not_process_upload')
      super
    end
  end
end
