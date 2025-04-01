# frozen_string_literal: true

class Course::PermissionsPresenter
  extend Forwardable

  def_delegator :@members, :each, :each_group
  attr_reader :course, :students

  def initialize(course)
    @course = course

    members!
  end

  Grant = Struct.new(:role_name)

  Member = Struct.new(:id, :full_name, :display_name, :email, :confirmed) do
    def confirmed?
      confirmed
    end
  end

  class GroupPresenter < PrivatePresenter
    attr_reader :name

    def each_grant
      grants.sort_by { it['role_name'] }.each do |grant|
        next unless (grant['context'] == @course.context_id) || (grant['context_name'] == 'root')

        yield Grant.new(
          role_name: grant.fetch('role_name')
        )
      end
    end

    def each_member
      members.each do
        yield Member.new(
          id:           it.fetch('id'),
          full_name:    it.fetch('full_name'),
          display_name: it.fetch('display_name'),
          email:        it.fetch('email'),
          confirmed:    it.fetch('confirmed')
        )
      end
    end

    def members?
      members.any?
    end

    private

    def data
      @data.value!
    end

    def members
      @members ||= data[0]&.value!
    end

    def grants
      @grants ||= data[1]&.value!
    end
  end

  private

  def members!
    @members = @course.special_groups.map do |group|
      group_name = ['course', @course.course_code, group].join '.'
      data = account_service.rel(:group).get({id: group_name}).then do |res|
        [res.rel(:members).get, res.rel(:grants).get]
      end
      GroupPresenter.new name: group, data:, course: @course
    end
    group_name = ['course', @course.course_code, 'students'].join '.'
    data = account_service.rel(:group).get({id: group_name}).then do |res|
      [nil, res.rel(:grants).get]
    end
    @students = GroupPresenter.new name: 'students', data:, course: @course
  end

  def account_service
    @account_service ||= Xikolo.api(:account).value!
  end
end
