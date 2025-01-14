# Permissions

Permissions in Xikolo are always bundled in roles.
These roles are granted to groups.
Roles, permissions, and grants are defined in `lib/tasks/permission/*.yml` files in `xi-account`.

The Xikolo application config additionally defines a list of grants that will be applied when new
courses (and their groups) are created, i.e. the course-specific permissions in the `course_groups` option
in `app/xikolo.yml`. Global (platform-wide) permission groups are defined in the `global_permission_groups` config in xi-web.

If you add new permissions or modify a role in a `permissions/*.yml` file, or add a new group in the
`global_permission_groups`, you can easily apply these changes (in your `development` environment) by executing
the `permissions:load` rake task in the account service.
This task is executed automatically in CI and during deployment for `production` instances.

The rake task will _not delete_ any permission, role, or group. Also, changes to the grant mapping for new courses in
Xikolo config will not be applied to existing courses. This is when [regranting permissions](regranting_permissions.md) is required.

Xikolo defines the following global roles:

- **GDPR Admins:** permissions for global administrators _with access to personal information_, e.g. user
  administration or granting of permissions.
- **Administrators:** other permissions for global administrators, e.g. content administration or (anonymized)
  reporting.
- **Helpdesk:** permissions for helpdesk agents, enabling them to process learner requests, e.g. concerning issues with quiz
  submissions, certificates, or the learning progress.
- **Quality Assurance:** permissions for content reviewers, who should be able to access all course content
  and news postings _before_ publication.
- **Global Course Stakeholders:** permissions for managers being responsible for multiple courses, including content
  preview and access to dashboards.

!!! note

    Not all of these roles are available on all platform instances. Custom configuration may be required.

!!! info

    The permissions for _GDPR Admins_ and _Administrators_ are disjoint. The rationale is that the privacy-by-design
    principle asks to give as few people access to as few personal information as possible, i.e. also administrators
    should only be able to access the information needed for their tasks. Together, both permission groups form a
    _"Super Admin"_, while only granting _GDPR Admin_ permissions without the regular platform administrator does not
    make sense.

    Bootstrapping administrators on console using the `adminize!` method will add the user to both groups,
    creating a _"Super Admin"_.
