# frozen_string_literal: true

class CustomSelectField < CustomField
  def validate(field, values, action)
    if action == :save && required? && values.empty?
      field.errors.add name, 'required'
    end

    if (values - self.values).any?
      field.errors.add name, 'values not allowed'
    end

    super
  end

  def type_name
    'select'
  end

  def cast(values)
    values = Array(values).map(&:to_s).sort
    values == default_values.sort ? nil : values
  end
end
