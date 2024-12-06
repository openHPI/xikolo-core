# frozen_string_literal: true

class Role < ApplicationRecord
  NAME_REGEXP = /\A\w+([.-]\w+)+\z/

  has_many :grants, dependent: :destroy

  validates :name,
    format: {with: NAME_REGEXP, message: 'invalid'},
    if: ->(record) { record.name.present? }

  class << self
    def resolve(param)
      if (uuid = UUID4.try_convert(param.to_s))
        find uuid
      else
        where(name: param.to_s).take!
      end
    end

    def lookup(principal:, context:)
      grants = Grant.lookup(principal:, context:)
      where(id: grants.select(:role_id))
    end

    def permissions(principal:, context:)
      lookup(principal:, context:)
        .pluck(:permissions)
        .flatten.uniq.sort
    end

    def with_permissions(permissions)
      where('roles.permissions::text[] @> array[?]', Array(permissions))
    end
  end
end
