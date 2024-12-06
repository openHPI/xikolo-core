# frozen_string_literal: true

module ActiveModel
  module Type
    class NewUpload < Value
      def initialize(**options)
        @upload_options = options
        super()
      end

      attr_reader :upload_options

      def type
        :new_upload
      end

      def declared(model, name, _value)
        model.process_with { Processor.new(name) }
      end

      class Value
        def self.from_upload(upload_id)
          if (uuid = ::UUID4.try_convert(upload_id))
            Upload.new(uuid)
          end
        end

        def self.from_url(url)
          return unless url

          Existing.new ::URI.parse(url.strip)
        rescue ::URI::InvalidURIError
          nil
        end

        class Upload
          def initialize(id)
            @id = id
          end

          def url
            nil
          end

          def upload_id
            @id
          end
        end

        class Existing
          def initialize(url)
            @url = url
          end

          def url
            @url.to_s
          end

          def upload_id
            nil
          end
        end
      end

      class Processor
        attr_reader :field_name

        def initialize(field_name)
          @field_name = field_name.to_s
        end

        def from_params(params, _obj)
          params.merge(
            @field_name => Value.from_upload(params[upload_id])
          )
        end

        def from_resource(params, _obj)
          params.merge(
            @field_name => Value.from_url(params[url])
          )
        end

        def to_resource(attributes, _obj)
          if attributes["delete_#{@field_name}"]
            attributes.delete(@field_name)
            attributes[uri] = nil
          end
          attributes.delete("delete_#{@field_name}")
          if attributes[@field_name]
            value = attributes.delete(@field_name)
            attributes[upload_id] = value.upload_id if value.upload_id
          end

          attributes
        end

        private

        def upload_id
          "#{@field_name}_upload_id"
        end

        def url
          "#{@field_name}_url"
        end

        def uri
          "#{@field_name}_uri"
        end

        def delete
          "delete_#{field_name}"
        end
      end
    end

    register :new_upload, NewUpload
  end
end
