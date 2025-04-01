# frozen_string_literal: true

class ImageUploadInput < SimpleForm::Inputs::Base
  enable :label, :errors, :hint, :required, :placeholder

  def input(opts = {})
    template.capture do
      template.tag.div(class: 'xui-imageupload', data:) do
        # For now, we need both params, {attribute_name}_upload_id and {attribute_name}_uri, to be backward compatible
        template.concat @builder.hidden_field(
          field_name,
          opts.merge(value: value.id, id: 'upload_id', autocomplete: 'off', disabled: true)
        )
        template.concat @builder.hidden_field(
          "#{attribute_name}_uri",
          opts.merge(id: 'uri', value: nil, autocomplete: 'off', disabled: true)
        )
        template.concat @builder.hidden_field(
          "delete_#{attribute_name}",
          {id: 'deletion', value: true, autocomplete: 'off', disabled: true}
        )
        template.concat current_image
        template.concat dropzone
      end
    end
  end

  private

  def value
    @value ||= options.fetch(:value) do
      ::FileUpload.new(**default_upload_options, **column.upload_options)
    end
  end

  def default_upload_options
    {
      content_type: 'image/*',
    }
  end

  def current_image
    template.tag.div(class: 'imageupload-current dropzone-previews') do
      template.tag.input(type: 'hidden', name: 'file_url', value: current_image_value)
    end
  end

  def dropzone
    template.tag.div(class: 'dropzone') do
      template.tag.div(class: 'xui-imageupload-zone xui-upload-target') do
        template.tag.div(dropzone_placeholder, class: 'dz-message')
      end
    end
  end

  def current_image_value
    if @builder.object.respond_to?(:"#{attribute_name}_url")
      @builder.object.send(:"#{attribute_name}_url")
    else
      value = @builder.object.send(attribute_name)
      value&.url
    end
  end

  def field_name
    if attribute_name.to_s.end_with? '_upload_id'
      attribute_name
    else
      "#{attribute_name}_upload_id"
    end
  end

  def dropzone_placeholder
    placeholder_text || I18n.t(:'simple_form.upload_image')
  end

  def data
    {
      imageupload: value.url,
      upload_id: value.id.to_s,
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

    I18n.t('flash.error.files.document.invalid_mime_type', allowed: value.extension_filter.join(', '))
  end
end
