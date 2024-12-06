# frozen_string_literal: true

class Grant < ApplicationRecord
  NULL = Object.new.freeze

  belongs_to :role
  belongs_to :context
  belongs_to :principal, polymorphic: true

  class << self
    def lookup(principal:, context:)
      scopes = []
      scopes << Grant.for(principal:)
      scopes << Grant.for(principal: Group.for(principal))

      within_context(context).merge(scopes.reduce(&:or))
    end

    def for(principal: NULL, type: NULL, context: nil)
      if principal.equal?(NULL) && type.equal?(NULL)
        none
      else
        if principal.equal?(NULL)
          where(principal_type: type.to_s)
        elsif type.equal?(NULL)
          where(principal:)
        else
          where(principal_id: principal, principal_type: type.to_s)
        end.within_context(context)
      end
    end

    def with_permission(permission)
      where(role: Role.with_permissions(permission))
    end

    def within_context(context)
      return all unless context

      where(context: Context.ascent(context).to_a)
    end
  end
end
