# frozen_string_literal: true

module QuizService
module Regrading # rubocop:disable Layout/IndentationWidth
  class Base
    def initialize(logger)
      @logger = logger
    end

    attr_accessor :logger

    def log(message, level)
      return if logger.nil?

      if level == :error
        logger.error(message)
      else
        logger.info(message)
      end
    end

    ##
    # Run a block in a translation and enforce DRY mode
    #
    # In DRY mode, the transaction is automatically rolled back.
    #
    def transaction(dry: false, &)
      if dry
        ActiveRecord::Base.transaction(requires_new: true) do
          log 'Running in DRY mode...', :info
          yield
          log 'DRY mode: Rolling back', :info

          raise ActiveRecord::Rollback.new('No persistence in DRY mode')
        end
      else
        ActiveRecord::Base.transaction(requires_new: true, &)
      end
    end
  end
end
end
