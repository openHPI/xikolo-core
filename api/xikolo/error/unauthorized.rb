# frozen_string_literal: true

module Xikolo
  module Error
    class Unauthorized < Base
      def initialize(status, msg)
        @status = status
        super(msg)
      end

      attr_reader :status
    end
  end
end
