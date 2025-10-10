# frozen_string_literal: true

class CustomField < ApplicationRecord
  self.table_name = :custom_fields

  has_many :custom_field_values, dependent: :delete_all

  scope :context, ->(ctx) { where context: ctx }

  validates :name, uniqueness: true

  after_commit :update_profile_completion,
    on: %i[create update destroy]

  def for(context)
    custom_field_values.find_by(context:)
  end

  def find_or_initialize_for(context)
    custom_field_values.find_or_initialize_by context:
  end

  def values
    val = super
    val.is_a?(Array) ? val : []
  end

  def default_values
    val = super
    val.is_a?(Array) ? val : []
  end

  def validate(field, values, action)
    if validator.present?
      validator = self.validator.constantize.new

      unless validator.call(self, field.context, values, action)
        validator.errors.each {|err| field.errors.add name, err }
      end
    end

    field.errors.empty?
  end

  def update_values(context, values, **)
    values = cast(values)

    fv = CustomFieldValue
      .includes(:custom_field)
      .find_or_initialize_by(custom_field: self, context:)

    if values || (fv.persisted? && required?)
      fv.values = values
      fv.save!(**)
    elsif fv.persisted?
      fv.destroy
    end

    self
  end

  private

  def update_profile_completion
    return unless saved_changes.include?('required')

    # Creating a new non-mandatory field will never change
    # profile completeness
    return if saved_changes['required'] == [nil, false]

    ProfileCompletion::UpdateAllJob.perform_later
  end

  class << self
    def seed!(values)
      find_or_initialize_by(name: values.fetch(:name)).update! values
    end

    def mandatory_completed?(context)
      where(required: true).all? do |f|
        CustomFieldValue.where(custom_field: f, context:).any?
      end
    end
  end
end
