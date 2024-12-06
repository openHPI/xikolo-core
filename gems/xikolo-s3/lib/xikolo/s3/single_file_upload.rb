# frozen_string_literal: true

module Xikolo::S3
  class SingleFileUpload
    class InvalidUpload < RuntimeError; end

    def initialize(id, purpose: nil)
      @id = UUID4.try_convert(id)
      @purpose = purpose
      @rejected_files = []
      @accepted_files = []
    end

    def empty?
      return true unless @id

      process!
      (@accepted_files.size + @rejected_files.size).zero?
    end

    def accepted_file!
      process!
      raise InvalidUpload if @accepted_files.size != 1

      @accepted_files[0]
    end

    private

    def bucket
      @bucket ||= Xikolo::S3.bucket_for(:uploads)
    end

    def process!
      return if @processed

      # request list of objects
      bucket.objects(prefix: "uploads/#{@id.to_str}").each do |summary|
        # receive data
        object = summary.object.load
        if valid? object
          @accepted_files << object
        else
          @rejected_files << object
        end
      end
      @processed = true
    end

    def valid?(object)
      # file must be processed:
      return false unless object.metadata['xikolo-state'] == 'accepted'
      return false if @purpose \
          && object.metadata['xikolo-purpose'] != @purpose.to_s

      true
    end
  end
end
