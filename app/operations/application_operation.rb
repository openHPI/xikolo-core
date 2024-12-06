# frozen_string_literal: true

class ApplicationOperation
  class << self
    def call(...)
      new(...).call
    end
  end

  ##
  # Return one of several result variants.
  #
  # Operations should use this to decorate the return values of `#call`.
  #
  # The result will be wrapped so that clients can use to decide what to do for
  # each type of result, without checking the type class.
  #
  #     OperationClass.call(...).on do |result|
  #       result.success { redirect_with_flash }
  #       result.failure { redirect_back_to_form_with_errors }
  #     end
  #
  # The block which will be executed is chosen based on the class name of the
  # result object returned from `#call`. The result object itself will be
  # passed to the handler block.
  #
  def result(result)
    ResultNegotiation.new result
  end

  class ResultNegotiation
    def initialize(result)
      @result = result

      @variants = {}
    end

    def on
      # Call the provided block to collect all response variants
      yield self

      # If a variant matches the result type, we can execute it
      @variants[result_variant_name].call @result
    end

    def method_missing(name, *args, &block)
      if block
        @variants[name.to_s] = block
      elsif name.end_with?('?')
        result_variant_name == name[..-2]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.end_with?('?') || super
    end

    private

    def result_variant_name
      @result.class.name.demodulize.underscore
    end
  end
end
