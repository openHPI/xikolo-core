# frozen_string_literal: true

class Course::Update < Course::Store
  def call
    if update # assign attributes and save
      grant_visitor!
      revoke_obsolete_visitor_grants!
    end

    @course
  end

  private

  def revoke_obsolete_visitor_grants!
    # fetch all grants with course.visitor role in the course context
    grants = account.rel(:grants).get({
      context: @course.context_id,
      role: 'course.visitor',
    }).value!

    # revoke all obsolete grants
    grants.each do |grant|
      grant.rel(:self).delete.value! if revoke_visitor_grant? grant
    end
  end

  def revoke_visitor_grant?(grant)
    # revoke all grants if course is in preparation
    return true if @course.status == 'preparation'

    # We only revoke the course.visitor role from groups.
    # The default groups having the course.course.show permission,
    # e.g. xikolo.admins through course.admin, are not
    # affected as the permission is directly added to these roles
    return (grant['group'] != 'all') if @course.groups.empty?

    @course.groups.exclude? grant['group']
  end
end
