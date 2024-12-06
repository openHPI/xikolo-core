# frozen_string_literal: true

module Xikolo::Validators
  class Base
    def errors
      @errors ||= []
    end

    def call(field, context, values, action)
      errors.clear
      validate field, context, values, action
      errors.empty?
    end
  end
end
