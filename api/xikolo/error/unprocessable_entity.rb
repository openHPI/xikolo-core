# frozen_string_literal: true

module Xikolo
  module Error
    class UnprocessableEntity < Base
      def initialize(status = 422, msg = '422 Unprocessable Entity')
        @status = status
        super(msg)
      end

      attr_reader :status
    end
  end
end
