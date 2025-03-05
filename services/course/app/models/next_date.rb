# frozen_string_literal: true

class NextDate < ApplicationRecord
  self.table_name = :dates
  self.primary_key = %i[slot_id user_id]
  self.inheritance_column = false # no single table inheritance (STI)

  validates :slot_id, uniqueness: {scope: :user_id}

  belongs_to :course

  class << self
    def active
      where('date > now() AND (visible_after IS NULL OR visible_after < now())')
    end

    def general
      where(user_id: nil_user_id)
    end

    def user_specific
      where.not(user_id: nil_user_id)
    end

    def for_user(user_id)
      return general if user_id.blank?

      for_user = arel_table[:user_id].eq(user_id)
      for_everybody = arel_table[:user_id].eq(nil_user_id)
      not_overwritten_for_user = arel_table[:slot_id]
        .not_in(unscoped.where(user_id:).select(:slot_id).arel)

      where(for_user.or(for_everybody.and(not_overwritten_for_user)))
    end

    def calc_id(resource_id, type)
      Digest::UUID.uuid_v5(resource_id, type)
    end

    def nil_user_id
      '00000000-0000-0000-0000-000000000000'
    end

    def order_by_date
      order Arel.sql <<~SQL.squish
        MIN(date) OVER (PARTITION BY course_id),
        date,
        section_pos,
        item_pos
      SQL
    end
  end
end
