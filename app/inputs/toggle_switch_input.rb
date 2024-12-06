# frozen_string_literal: true

class ToggleSwitchInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    input_html_classes << :'toggle-switch'
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    if nested_boolean_style?
      build_hidden_field_for_checkbox +
        build_check_box_without_hidden_field(merged_input_options) +
        switch_label +
        (inline_label || '')
    else
      build_check_box(unchecked_value, merged_input_options) + switch_label
    end
  end

  def switch_label
    "<label for='#{switch_label_target}' " \
    "class='#{switch_label_class}'>#{input_options[:toggle_label]}</label>".html_safe # rubocop:disable Rails/OutputSafety
  end

  def switch_label_class
    [object_name, label_target].join('_')
  end

  def switch_label_target
    return input_html_options[:id] if input_html_options[:id].present?
    return [object_name, label_target].join('_') if @builder.options[:namespace].blank?

    [@builder.options[:namespace], object_name, label_target].join('_')
  end
end
