# frozen_string_literal: true

module AccountService
class CustomTextField < CustomField # rubocop:disable Layout/IndentationWidth
  def default_values
    [super.first.to_s]
  end

  def type_name
    'text'
  end

  def cast(values)
    str = Array(values).first&.strip
    str.blank? ? nil : [str]
  end

  def validate(field, values, action)
    if action == :save && required? && values.first.blank?
      field.errors.add name, 'required'
      return
    end

    super
  end
end
end
