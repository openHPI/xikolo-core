# frozen_string_literal: true

class UploadInput < SimpleForm::Inputs::Base
  enable :label, :errors, :hint, :required, :placeholder

  def input(opts = {})
    template.capture do
      template.tag.div(class: 'xui-upload', data:) do
        template.concat @builder.hidden_field(field_name, opts.merge({value: value.id, id: nil}))
        template.concat dropzone
        template.concat input_options.delete(:extra_html) if input_options.key? :extra_html
      end
    end
  end

  private

  def value
    @value ||= options.fetch(:value) do
      next column.upload if column.respond_to? :upload

      @builder.object.send attribute_name
    end
  end

  def dropzone
    template.tag.div(class: 'xui-upload-zone xui-upload-target') do
      template.tag.div(dropzone_placeholder, class: 'dz-message')
    end
  end

  def field_name
    if attribute_name.to_s.end_with?('_uri')
      # This is a workaround letting us add errors to the form field
      # (since the actual attribute on the model is called ``*_uri``).
      attribute_name.to_s.gsub('_uri', '_upload_id').to_sym
    elsif attribute_name.to_s.end_with?('_upload_id')
      attribute_name
    else
      "#{attribute_name}_upload_id"
    end
  end

  def dropzone_placeholder
    placeholder_text || I18n.t(:'simple_form.upload_single_file')
  end

  def data
    {
      upload: value.url,
      s3: payload,
      id: input_class,
      'max-filesize': value.size&.max,
      'error-size': error_size,
      'error-type': error_type,
    }.compact
  end

  def payload
    value.fields.merge(key: value.prefix, content_type: value.content_type)
  end

  def error_size
    return nil unless value.size

    I18n.t('flash.error.files.attachment_file_size_exceeded')
  end

  def error_type
    return nil if value.extension_filter.empty?

    # Ensure that all valid content_types are included in the #extension_filter
    # Otherwise, the error message will omit some valid types
    I18n.t('flash.error.files.document.invalid_mime_type', allowed: value.extension_filter.join(', '))
  end
end
