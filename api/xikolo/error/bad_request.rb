# frozen_string_literal: true

module Xikolo
  module Error
    class BadRequest < Base
      def status
        400
      end
    end
  end
end
