# frozen_string_literal: true

class ProfileDecorator
  attr_reader :user

  def initialize(fields, user)
    @fields = fields.to_a
    @values = CustomFieldValue.where(context: user,
      custom_field_id: @fields.map(&:id)).to_a
    @user = user
  end

  def as_json(opts = {})
    {
      user_id: user.id,
      fields:,
    }.as_json(opts)
  end

  def as_event(**kwargs)
    {
      user: user.id,
      fields:,
    }.as_json(kwargs)
  end

  private

  def fields
    CustomFieldDecorator.decorate_collection(
      @fields,
      context: {user_values: @values}
    )
  end
end
