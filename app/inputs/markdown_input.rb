# frozen_string_literal: true

class MarkdownInput < SimpleForm::Inputs::TextInput
  def input(_opts)
    template.capture do
      template.concat markdown_editor
      template.concat validaton_form_message
    end
  end

  private

  def markdown_editor
    template.tag.div(
      class: "markdown-editor #{'markdown-editor--with-uploads' if uploads?}",
      data: {behavior: 'markdown-editor-wrapper'}
    ) do
      if uploads?
        input_with_uploads
      else
        input_without_uploads
      end
    end
  end

  def resize_btn
    template.tag.button(class: 'markdown-editor__resize-btn', type: 'button', id: "#{label_target}-resize",
      title: I18n.t(:'components.markdown_editor.expand'), aria_label: I18n.t(:'components.markdown_editor.expand'))
  end

  def validaton_form_message
    template.tag.p(class: 'markdown-editor__error-message', data: {behavior: 'markdown-editor-error'},
      id: "#{label_target}-error")
  end

  def input_without_uploads
    template.concat form_textarea
    template.concat template.tag.div(data: {behavior: 'markdown-editor-widget', image_upload: 'false'})
    template.concat resize_btn
  end

  def input_with_uploads
    template.concat upload_fields_wrapper
    template.concat dropzone
  end

  def upload_fields_wrapper
    template.tag.div(class: 'upload_fields_wrapper') do
      template.concat editor_with_uploads
      template.concat template.tag.div(data: {behavior: 'markdown-editor-widget', image_upload: 'true'})
      template.concat resize_btn
    end
  end

  def editor_with_uploads
    value = model_value
    if value.respond_to?(:to_hash)
      value = value.to_hash
    else
      value = {'markup' => value}
    end
    template.tag.div(class: 'upload_fields') do
      template.concat urlmapping_field value
      template.concat otherfiles_field value
      template.concat form_textarea_with_uploads value
    end
  end

  def urlmapping_field(value)
    @builder.hidden_field :"#{attribute_name}_urlmapping",
      value: JSON.dump(value['url_mapping'] || {}),
      id: "#{label_target}-urlmapping",
      namespace: false
  end

  def otherfiles_field(value)
    @builder.hidden_field :"#{attribute_name}_otherfiles",
      value: JSON.dump(value['other_files'] || {}),
      id: "#{label_target}-otherfiles",
      namespace: false
  end

  def form_textarea_with_uploads(value)
    @builder.text_area attribute_name,
      **input_html_options,
      data: {
        behavior: 'markdown-form-input',
        'upload-dropzone': "#xui-mdupload-#{base_id}",
        'url-mapping': "##{label_target}-urlmapping",
        'other-files': "##{label_target}-otherfiles",
      },
      dir: 'auto',
      id: label_target,
      namespace: false,
      value: value['markup']
  end

  def dropzone
    template.tag.div(
      class: 'dropzone',
      id: "xui-mdupload-#{base_id}",
      data: dropzone_data
    ) do
      template.tag.div(class: 'xui-mdupload-zone xui-upload-target') do
        # Dropzone placeholder
        template.tag.div(I18n.t(:'simple_form.upload_file'), class: 'dz-message')
      end
    end
  end

  def dropzone_data
    upload = ::FileUpload.new(**upload_attrs)
    {
      mdupload: upload.url,
      upload_id: upload.id.to_s,
      textarea_id: "##{label_target}",
      s3: upload.fields.merge(
        key: upload.prefix,
        content_type: upload.content_type
      ),
    }
  end

  def form_textarea
    additional_options = {}

    value = model_value
    if value.is_a?(Hash) && value.key?('markup')
      additional_options[:value] = value['markup']
    end

    @builder.text_area attribute_name,
      **input_html_options,
      data: {behavior: 'markdown-form-input'},
      dir: 'auto',
      id: label_target,
      **additional_options
  end

  def label_target
    "markdown-input-#{base_id}"
  end

  def label(wrapper_options = nil)
    # overwrite label to use label_target directly without prefixing the resource name
    label_options = merge_wrapper_options(label_html_options, wrapper_options)
    template.label_tag(label_target, label_text, label_options)
  end

  def base_id
    [@builder.options[:namespace], options[:markdown_id_suffix]].compact.join('_').presence || attribute_name
  end

  def model_value
    if options.key? :value
      options[:value]
    elsif options.key?(:input_html) && options[:input_html].key?(:value)
      options[:input_html][:value]
    elsif @builder.object.respond_to?(attribute_name)
      @builder.object.send attribute_name
    end
  end

  def uploads?
    upload_attrs
  end

  def upload_attrs
    return options[:uploads] if options.key? :uploads

    column.uploads.presence if column.respond_to?(:uploads)
  end
end
