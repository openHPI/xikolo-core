# frozen_string_literal: true

module Xikolo
  module Error
    class NotFound < Base
      def status
        404
      end
    end
  end
end
