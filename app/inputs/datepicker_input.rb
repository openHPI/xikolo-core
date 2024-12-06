# frozen_string_literal: true

class DatepickerInput < SimpleForm::Inputs::Base
  enable :placeholder

  def input(wrapper_options = nil)
    input_html_classes.shift # 'date'
    input_html_classes.push 'string'
    input_html_classes.push 'form-control'
    input_html_options[:data] = {behaviour: 'datepicker'}
    input_html_options[:autocomplete] = 'off'
    input_html_options[:value] = formatted_value

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end

  private

  def formatted_value
    if options.key? :value
      options[:value]
    else
      @builder.object.send(attribute_name)&.iso8601
    end
  end
end
