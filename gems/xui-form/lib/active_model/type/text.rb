# frozen_string_literal: true

require 'active_model/type/xikolo_string'

module ActiveModel
  module Type
    class Text < XikoloString
      def type
        :text
      end
    end

    register :text, Text
  end
end
