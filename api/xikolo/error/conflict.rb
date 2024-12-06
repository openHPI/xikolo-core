# frozen_string_literal: true

module Xikolo
  module Error
    class Conflict < Base
      def status
        409
      end
    end
  end
end
