# frozen_string_literal: true

class Cmi5ItemUnzipJob < ApplicationJob
  queue_as :default

  def perform(cmi5_item)
    cmi5_item.files.destroy_all

    cmi5_item.package.open do |package|
      Zip::File.open(package.path) do |zip_file|
        zip_file.each do |entry|
          next unless entry.file?

          # The unzipped content is always nested in a root folder. This
          # parent folder needs to be removed from the path.
          file_path = entry.name.sub(%r{\A[^/]+/}, '')
          io = StringIO.new(entry.get_input_stream.read)
          filename = File.basename(entry.name)
          io.rewind

          file = ActiveStorage::Blob.create_and_upload!(io:, filename:)

          # ActiveStorage detects the content_type by file content, which is
          # wrong for two kinds of Storyline asset: chunked JavaScript files
          # that contain SVG images, and HTML files that start with a UTF-8 BOM.
          # Force the content_type by filename in these cases.
          content_type = if filename.ends_with?('.html')
                           'text/html'
                         elsif filename.ends_with?('js')
                           'application/javascript'
                         end
          file.update!(content_type:) if content_type

          Cmi5::File.create!(cmi5_item:, file_path:, file:)
        end
      end
    end

    Cmi5ItemAnalyzeJob.perform_later(cmi5_item)
  end
end
