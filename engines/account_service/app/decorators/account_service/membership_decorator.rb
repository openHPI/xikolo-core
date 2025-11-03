# frozen_string_literal: true

module AccountService
class MembershipDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      url: self_path,
      user: user_id,
      user_url: user_path,
      group: group.to_param,
      group_url: group_path,
    }.as_json(opts)
  end

  def self_path
    h.membership_path self
  end

  def user_path
    h.user_path user_id
  end

  def group_path
    h.group_path group
  end

  class << self
    def decorate_collection(scope, *)
      # Ensure to eager-load groups as they are needed by the decorator. This
      # avoids a N+1 query for each membership to fetch the group.
      super(scope.includes(:group), *)
    end
  end
end
end
