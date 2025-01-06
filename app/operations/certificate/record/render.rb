# frozen_string_literal: true

module Certificate
  class Record
    class Render < ::ApplicationOperation
      def initialize(record)
        super()

        @record = record
      end

      def call
        RecordRenderer.as_pdf(@record.render_data)
      end
    end
  end
end
