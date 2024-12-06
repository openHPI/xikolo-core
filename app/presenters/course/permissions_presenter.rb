# frozen_string_literal: true

class Course::PermissionsPresenter
  extend Forwardable

  def_delegator :@members, :each, :each_group
  attr_reader :course, :students

  def initialize(course)
    @course = course

    members!
  end

  private

  def members!
    @members = @course.special_groups.map do |group|
      group_name = ['course', @course.course_code, group].join '.'
      data = account_service.rel(:group).get(id: group_name).then do |res|
        [res.rel(:members).get, res.rel(:grants).get]
      end
      GroupPresenter.new name: group, data:, course: @course
    end
    group_name = ['course', @course.course_code, 'students'].join '.'
    data = account_service.rel(:group).get(id: group_name).then do |res|
      [nil, res.rel(:grants).get]
    end
    @students = GroupPresenter.new name: 'students', data:, course: @course
  end

  class GroupPresenter < PrivatePresenter
    attr_reader :name

    def each_grant
      @data.value![1].value.sort_by {|grant| grant['role_name'] }.each do |grant|
        if (grant['context'] == @course.context_id) || (grant['context_name'] == 'root')
          yield grant
        end
      end
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
