# frozen_string_literal: true

module Form
  class FileUploadPreview < ViewComponent::Preview
    # @!group

    # The defaults: a generic "attach file" zone for a single file.
    def default
      render_with_template
    end

    # Icon and wording are per use case — here, uploading a video.
    def video
      render_with_template
    end

    # Several files at once, restricted to images.
    def multiple
      render_with_template
    end

    def with_error
      short = CourseService::Short.new
      short.errors.add(:video, 'File size must be less than or equal to 10 MB (current size is 14.2 MB)')

      render_with_template(locals: {short:})
    end
    # @!endgroup
  end
end
