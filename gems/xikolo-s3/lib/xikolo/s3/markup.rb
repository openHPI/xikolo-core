# frozen_string_literal: true

require 'active_model'

module Xikolo
  module S3
    class Markup < ActiveModel::Type::Value
      attr_reader :uploads

      def initialize(uploads: nil)
        @uploads = uploads
        super()
      end

      def type
        :xikolo_s3_markup
      end

      def cast_value(value)
        Field.new(value)
      end

      def serialize(value)
        value.to_s.presence
      end

      class Field
        def initialize(markup)
          @markup = markup
        end

        def file_refs
          S3.extract_file_refs(@markup)
        end

        def url_mapping
          media_refs[:url_mapping]
        end

        def other_files
          media_refs[:other_files]
        end

        def external
          @external ||= Xikolo::S3.externalize_file_refs(@markup, public: true)
        end

        def to_s
          @markup
        end

        def to_hash
          {
            'markup' => @markup,
            'url_mapping' => url_mapping,
            'other_files' => other_files,
          }
        end

        private

        def media_refs
          @media_refs ||= Xikolo::S3.media_refs(@markup, public: true)
        end
      end
    end
  end
end
