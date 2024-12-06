# frozen_string_literal: true

module Xikolo
  module Error
    class Base < StandardError
      def status
        500
      end
    end
  end
end
