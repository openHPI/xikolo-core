# frozen_string_literal: true

module Certificate
  class Certificate < Record
    has_one_attached :pdf
  end
end
