# frozen_string_literal: true

# http://stackoverflow.com/questions/14972253/simpleform-default-input-class
# https://github.com/plataformatec/simple_form/issues/316

Rails.root.glob('app/inputs/*.rb').each {|f| require f }

inputs = %w[
  CollectionSelectInput
  DateTimeInput
  FileInput
  GroupedCollectionSelectInput
  NumericInput
  PasswordInput
  RangeInput
  StringInput
  TextInput
]

inputs.each do |input_type|
  superclass = "SimpleForm::Inputs::#{input_type}".constantize

  new_class = Class.new(superclass) do
    def input_html_classes
      super.push('form-control')
    end
  end

  Object.const_set(input_type, new_class)
end

module SubmitButtonPrimary
  def submit_button(*args, &)
    options = args.extract_options!.dup
    options[:class] = ['btn', 'btn-primary', options[:class]].compact
    args << options

    submit(*args, &)
  end

  SimpleForm::FormBuilder.include SubmitButtonPrimary
end

module SimpleForm::Components::Pattern
  def pattern(_wrapper_options = nil)
    # browsers do not support \A and \z for (multiline) regexes:
    input_html_options[:pattern] ||= begin
      pattern = pattern_source
      if pattern
        pattern = "^#{pattern[2..]}" if pattern.start_with? '\\A'
        pattern = "#{pattern[0..-3]}$" if pattern.end_with? '\\z'
      end
      pattern
    end
    nil
  end
end

module SimpleFormDynamicDefaultFormClass
  def simple_form_for(record, options = {})
    options[:html] ||= {}
    unless options[:html].key?(:class)
      wrapper = options.fetch(:wrapper, SimpleForm.default_wrapper)
      if %i[bootstrap3_horizontal larger_labels].include? wrapper
        options[:html][:class] = 'form-horizontal'
      end
    end
    super
  end
end

ActiveSupport.on_load(:action_view) do
  include SimpleFormDynamicDefaultFormClass
  include AdvancedOptionsHelpers
end

module SimpleFormTranslateWithVariables
  def initialize(builder, attribute_name, column, input_type, options = {})
    options = options.dup
    @i18n_variables = options.delete(:i18n_variables)
    super(builder, attribute_name, column, input_type, options) # rubocop:disable Style/SuperArguments
  end

  def translate_from_namespace(*args)
    translated = super
    return translated unless translated && @i18n_variables

    I18n.interpolate translated, @i18n_variables
  end

  SimpleForm::Inputs::Base.prepend SimpleFormTranslateWithVariables
end

module AdvancedOptionsHelpers
  def advanced_settings(column_offset: 2, &)
    id = SecureRandom.uuid

    capture do
      concat advanced_settings_button(id, column_offset)
      concat tag.div(capture(&), id:)
    end
  end

  def advanced_settings_button(id, column_offset)
    show_text = I18n.t :'buttons.show_advanced_settings'
    hide_text = I18n.t :'buttons.hide_advanced_settings'

    tag.div do
      tag.button(show_text, class: "btn-xs btn btn-default col-lg-offset-#{column_offset} mb15",
        'data-behavior': 'toggle-visibility',
        data: {
          'toggle-visibility': id,
          'toggle-text-on': show_text,
          'toggle-text-off': hide_text,
        },
        type: 'button')
    end
  end
end

SimpleForm::FormBuilder.map_type :boolean, to: ToggleSwitchInput
SimpleForm::FormBuilder.map_type :markup, to: MarkdownInput
SimpleForm::FormBuilder.map_type :xikolo_s3_markup, to: MarkdownInput
SimpleForm::FormBuilder.map_type :datetime, to: DatepickerInput
SimpleForm::FormBuilder.map_type :single_line_string, to: SimpleForm::Inputs::StringInput
SimpleForm::FormBuilder.map_type :uri, to: SimpleForm::Inputs::StringInput
SimpleForm::FormBuilder.map_type :upload, to: UploadInput

# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.boolean_style = :nested
  config.button_class = 'btn'
  config.error_method = :to_sentence

  config.default_wrapper = :bootstrap3_horizontal
  config.wrappers(
    :bootstrap3_horizontal,
    tag: 'div',
    class: 'form-group',
    error_class: 'has-error'
  ) do |b|
    b.use :html5
    b.use :min_max
    b.use :maxlength
    b.use :placeholder

    b.use :pattern
    b.use :readonly

    b.use :label, class: 'col-lg-2 col-md-2'
    b.wrapper :right_column, tag: :div, class: 'col-lg-10 col-md-10' do |component|
      component.wrapper tag: 'div' do |ba|
        ba.use :input
        ba.use :hint,  wrap_with: {tag: 'span', class: 'help-block'}
        ba.use :error, wrap_with: {tag: 'div', class: 'help-block has-error'}
      end
    end
  end

  # like bootstrap3_horizontal, but more space for the labels:
  config.wrappers(
    :larger_labels,
    tag: 'div',
    class: 'form-group',
    error_class: 'has-error'
  ) do |b|
    b.use :html5
    b.use :min_max
    b.use :maxlength
    b.use :placeholder

    b.use :pattern
    b.use :readonly

    b.use :label, class: 'col-lg-3 col-md-3'
    b.wrapper :right_column, tag: :div, class: 'col-lg-9 col-md-9' do |component|
      component.wrapper tag: 'div' do |ba|
        ba.use :input
        ba.use :hint,  wrap_with: {tag: 'span', class: 'help-block'}
        ba.use :error, wrap_with: {tag: 'div', class: 'help-block has-error'}
      end
    end
  end

  # a little bit like bootstrap3_horizontal, but misses some styling
  # mostly a legacy wrapper to fix styling of already build forms
  config.wrappers(
    :compact,
    tag: 'div',
    class: 'form-group',
    error_class: 'has-error'
  ) do |b|
    b.use :html5
    b.use :min_max
    b.use :maxlength
    b.use :placeholder

    b.use :pattern
    b.use :readonly

    b.use :label
    b.wrapper :right_column, tag: :div do |component|
      component.wrapper tag: 'div' do |ba|
        ba.use :input
        ba.use :hint,  wrap_with: {tag: 'span', class: 'help-block'}
        ba.use :error, wrap_with: {tag: 'div', class: 'help-block has-error'}
      end
    end
  end
end
