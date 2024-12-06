# frozen_string_literal: true

module Xikolo
  module Error
    class InvalidValue < Base
      def status
        400
      end
    end
  end
end
