# frozen_string_literal: true

module Form
  # A file input rendered as a drop zone with a list of the selected files.
  #
  # Files can be picked through the button or dropped onto the zone. Each file
  # gets a row showing its name, and — for `direct_upload: true` fields — the
  # upload progress once the form is submitted.
  class FileUpload < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] the form the field belongs to
    # @param attribute [Symbol] the attribute to build the field for
    # @param icon [String] name of the Pixelart icon shown in the drop zone
    # @param title [String] headline of the drop zone, e.g. "Upload video"
    # @param hint [String] line below the title, e.g. accepted formats
    # @param button_label [String] label of the file picker button
    # @param options [Hash] additional options for the file field, e.g.
    #   `accept`, `multiple` or `direct_upload`
    def initialize(form, attribute, icon: 'attachment', title: nil, hint: nil,
                   button_label: nil, **options)
      @form = form
      @attribute = attribute
      @icon = icon
      @title = title
      @hint = hint
      @button_label = button_label
      @options = options
    end

    attr_reader :icon

    def title
      @title || t(:'components.file_upload.title')
    end

    def hint
      @hint || t(:'components.file_upload.hint')
    end

    def button_label
      @button_label || t(:'components.file_upload.button')
    end

    # Validation messages for the attribute, e.g. an unsupported content type.
    def errors
      return [] unless @form.object.respond_to?(:errors)

      @form.object.errors[@attribute]
    end

    def hint_id
      @form.field_id(@attribute, :hint)
    end

    def error_id
      @form.field_id(@attribute, :error)
    end

    # Both the hint and, when present, the error describe the input.
    def described_by
      [hint_id, (error_id if errors.any?)].compact.join(' ')
    end

    def list_id
      @form.field_id(@attribute, :list)
    end
  end
end
