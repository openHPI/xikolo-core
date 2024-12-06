# frozen_string_literal: true

class CustomFieldValue < ApplicationRecord
  belongs_to :custom_field
  belongs_to :context, polymorphic: true, optional: true

  validate :values_allowed?

  def values_allowed?(values = self.values, action = :save)
    custom_field.validate self, values, action
  end

  def values
    vals = super
    vals = [] if vals.nil?
    values_allowed?(vals, :read) ? vals : custom_field.default_values
  end

  class << self
    def for_members_of(group)
      where(context_type: 'User', context_id: group.member_ids_relation)
    end

    def histograms(fields = CustomField.where(type: 'CustomSelectField'))
      value_stats = where(custom_field: fields)
        .group(:custom_field_id, :values)
        .pluck(:custom_field_id, :values, arel_table[Arel.star].count.as('count'))
        .group_by(&:first)

      fields = CustomField.where(id: value_stats.keys).index_by(&:id)

      value_stats.each_pair.to_h do |id, stats|
        histogram = stats.each_with_object({}) do |row, memo|
          _, values, count = row
          memo[values[0]] = count unless values == fields[id].default_values
        end

        [fields[id], histogram]
      end
    end
  end
end
