# frozen_string_literal: true

class PermissionsPresenter
  extend Forwardable
  def_delegator :@members, :each, :each_group

  def initialize
    members!
  end

  private

  def members!
    @members = Xikolo.config.global_permission_groups.map do |group|
      group_name = "xikolo.#{group}"
      data = account_service.rel(:group).get(id: group_name).then do |res|
        [res.rel(:members).get, res.rel(:grants).get]
      end
      GroupPresenter.new name: group, data:
    end
  end

  class GroupPresenter < PrivatePresenter
    attr_reader :name

    def each_grant(&)
      @data.value![1].value.sort_by {|grant| grant['role_name'] }.each(&)
    end

    def each_member(&)
      @data.value![0].value.each(&)
    end

    def members?
      @data.value![0].value.any?
    end
  end

  def account_service
    @account_service ||= Xikolo.api(:account).value!
  end
end
