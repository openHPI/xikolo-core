# frozen_string_literal: true

module ActiveModel
  module Type
    class Upload < UUID
      def initialize(options)
        @upload_options = options
        super()
      end

      def type
        :upload
      end

      def upload
        # regenerate new instance per call to create a new ticket per request
        ::FileUpload.new(**@upload_options)
      end
    end

    register :upload, Upload
  end
end
