# frozen_string_literal: true

module ActiveModel::Type
  class XikoloString < String
    def cast_value(value)
      return nil if value.blank?

      super(value.gsub("\r\n", "\n"))
    end
  end
end
