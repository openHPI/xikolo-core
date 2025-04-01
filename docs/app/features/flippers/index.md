# Feature flippers

Feature flippers allow enabling and disabling specific platform features dynamically.
They can be controlled per platform, user group, or individual user - and even limited to specific contexts (such as courses).

!!! tip

    For development, this also enables continuous deployment by deploying "unfinished" features, hidden behind such a flipper.

See below for explanations on [managing feature flippers](#manage-feature-flippers) (creating a flipper and using it in the code).

!!! info "Annotations"

    - :material-test-tube: Experimental and temporary features intended for migration purposes or prototypical use.
    - :material-code-tags-check: Feature is programmatically enabled / disabled, typically part of a broader feature set, and is tied to a specific user.
    - :material-delete-alert-outline: Deprecated feature, which is planned to be removed.

## List of features

`account.login`

:   Enable (native) platform login: This will enable password reset and shows the login form (with user / password input).

    *Scope:* `Group.all_users`, `Context.root`

`account.registration`

:   Enable (native) platform registration: This will show the registration form and the respective button for the login form.

    *Scope:* `Group.all_users`, `Context.root`

`announcements`

:   Enable accessing "global" announcements (admin- and user-facing pages) on the platform (including the start page) as well as publishing them via email.

    *Scope:* `Group.all_users`, `Context.root`

    !!! note

        This is *not* referring to "targeted announcements". See the `admin_announcements` feature below.

`admin_announcements` :material-test-tube:

:   Enable the new admin-only announcement overview (accessible via platform admin menu).

    *Scope:* `Group.administrators`, `Context.root`

`alternative_sections.create`

:   Enables the ability to create alternative sections. This doesn't affect existing alternative sections, these can be visited and edited without this flipper.

    *Scope:* `Group.all_users`, `Context.root`

`certificate_requirements`

:   Display the certificate requirements on the course page.

    *Scope:* `Group.all_users`, `Context.root`

`collabspace_calendar`

:   Enable calendars in collaboration spaces.

    *Scope:* `Group.all_users`, `Context.root`

`collabspace_calendar.all_day_events`

:   Display the "all-day event" toggle button in the collaboration space calendar event form.

    *Scope:* `Group.all_users`, `Context.root`

    !!! info

        This feature must be used in conjunction with the `collabspace_calendar` feature.

`course.access-group`

:   Allow courses that are only accessible for certain user groups, usually coupled with SSO.

    *Scope:* `Group.all_users`, `Context.root`

`course.certificates_tab` :material-test-tube:

:   Enable the separate certificates tab for courses, adding it to the course navigation.

    *Scope:* `Group.all_users`, `Context.root`

`course.reactivated` :material-code-tags-check:

:   This user has purchased a course reactivation for a specific course; items are fetched for this user (thus: overriding caching), in order to apply enforced submission deadlines.

    *Scope:* `User`, `Course`

    !!! info

        The feature is set programmatically. Set the `course_reactivation` flipper to allow course reactivations for the platform.

`course.required_items`

:   Enable the admin interface for adding required items to a learning unit.

    *Scope:* `Group.administrators`, `Context.root`

`course_dashboard.show_cops_details` :material-test-tube:

:   Display detailed CoPs statistics (at the course end and since the course end) on the course dashboard. Hidden by default until results are deemed reliable.

    *Scope:* `Group.all_users`, `Context.root`

`course_details.learning_goals`

:   Display the learning goals on the course details page.

    *Scope:* `Group.all_users`, `Context.root`

`course_list`

:   Enable the global course list.

    *Scope:* `Group.all_users`, `Context.root`

    !!! warning

        :material-layers-outline: Should be disabled on "headless" platforms that sit behind a custom portal.

`course_rating`

:   Enable the course rating widget on the course details pages.

    *Scope:* `Group.all_users`, `Context.root`

`course_reactivation`

:   Enable course reactivation for the platform. Course reactivation can then be enabled individually per course via UI.

    *Scope:* `Group.all_users`, `Context.root`

`chatbot.prototype-2` :material-test-tube:

:   Enable the chatbot prototype in the helpdesk widget.

    *Scope:* `Group.all_users`, `Context.root`

    !!! info

        This requires the chatbot backend to be set up properly. Further configuration is required.

`dashboard.course_recommendations`

:   Enable the course recommendation widget on the user's dashboard, showing courses for promotion (e.g., current or upcoming courses).

    *Scope:* `Group.all_users`, `Context.root`

`gamification`

:   Enable gamification for the platform (e.g., XP in navigation and user badges in the discussion forum).

    *Scope:* `Group.all_users`, `Context.root`

`geo_ip_block`

:   Block users from Russia and Belarus on the registration pages.

    *Scope:* `Group.all_users`, `Context.root`

`ical_feed`

:   Enable the iCal feed for the user's next (course) dates (button on the dashboard).

    *Scope:* `Group.all_users`, `Context.root`

`integration.external_booking`

:   Enable integration with external booking tools for courses. This adds a JWT token to external registration URLs.

    *Scope:* `Group.all_users`, `Context.root`

`new_pinboard.phase-1.2` :material-test-tube:

:   Enable the new pinboard prototype, i.e. a specific variant of the discussion forum.

    *Scope:* `User`, `Course (A/B tests)`

`open_mode`

:   Enable the preview of video items for anonymous or non-enrolled users for items that are flagged for 'open mode' via the item settings.

    *Scope:* `Group.all_users`, `Context.root`

    !!! warning

        Do not enable this feature for staging / testing systems.

`password_change.remove_sessions`

:   Log out users on other browsers when they change their password in the profile.

    *Scope:* `Group.all_users`, `Context.root`

`preview_graded_quiz_points`

:   Display achieved score (*not* the results) for graded quizzes immediately after submission.

    *Scope:* `Group.all_users`, `Context.root`

`primary_email_suspended` :material-code-tags-check:

:   Disable email notifications and show a warning for users where emails to the primary email bounced.

    *Scope:* `User`, `Context.root`

    !!! info

        The feature is set programmatically.

`proctoring` :material-delete-alert-outline:

:   Enable proctoring for the platform. Proctoring can be enabled individually per course, there is a course-specific `proctored` setting.

    *Scope:* `Group.all_users`, `Context.root`

    !!! info

        This feature requires further configuration. The following keys must be set in the `config/secrets.yml` file:

        ```yaml
        smowl_entity: my_entity
        smowl_password: my_password
        ```

`profile`

:   Enable the user profile page.

    *Scope:* `Group.all_users`, `Context.root`

    !!! warning

        :material-layers-outline: Should be disabled on "headless" platforms that sit behind a custom portal.

`quiz_recap`

:   Enable the quiz recap feature in the course area.

    *Scope:* `Group.all_users`, `Context.root`

`records.exclude_birthdate` :material-test-tube:

:   Hide notes / hints about the preference to display a user's birthdate on records.

    *Scope:* `Group.all_users`, `Context.root`

`social_sharing.certificate`

:   Enable social sharing for open badges on the certificates page.

    *Scope:* `Group.all_users`, `Context.root`

`time_effort` :material-test-tube:

:   Enable time effort estimation shown in the item navigation and on the item page.

    *Scope:* `Group.all_users`, `Context.root`

    !!! info

        This requires the time effort service to be set up for the platform.

`time_effort.video_only` :material-test-tube:

:   Enable time effort estimation shown in the item navigation and on the item page.

    *Scope:* `Group.all_users`, `Context.root`

    !!! info

        This feature must be used in conjunction with the `time_effort` feature.

`users.search_by_auth_uid`

:   Allow admins to search users via authorization UID.

    *Scope:* `Group.administrators`, `Context.root`

`video_slide_thumbnails` :material-test-tube:

:   Enable slide thumbnails in the video player.

    *Scope:* `Group.all_users`, `Context.root`

## Manage feature flippers

This section explains how to manage feature flippers for a platform.

### Enable features

For enabling a specific feature - either locally or for a production system - a corresponding `Feature` record needs to be created via Rails console (`account` service):

=== "For a specific user"

    ``` ruby
    Feature.create!(
      name: 'feature_name',
      value: true,
      owner: User.find(user_id),
      context: Context.root      # or a specific (course) context
    )
    ```

=== "For a global group"

    ``` ruby
    Feature.create!(
      name: 'feature_name',
      value: true,
      owner: Group.all_users,    # or a any other group
      context: Context.root
    )
    ```

This will enable the `feature_name` feature for the respective users in the given context.

The following global special groups can be used:

- `Group.active_users` - all confirmed, non-archived users
- `Group.administrators` - all members of the group `xikolo.administrators`
- `Group.affiliated_users` - all active users with the affiliated flag
- `Group.all_users` - all users (including anonymous, non-confirmed, archived)
- `Group.confirmed_users` - all confirmed users (including archived)
- `Group.unconfirmed_users` - all unconfirmed users (including anonymous)
- `Group.archived_users` - all archived users

!!! tip "Feature owners"

    ``` ruby
    User.find('00000000-0000-0000-0000-000000000000')  # Query user by ID
    User.query('jane.doe@example.com').first           # Query user by email

    Group.find('00000000-0000-0000-0000-000000000000') # Query group by ID
    Group.active_users                                 # Use a special group
    ```

### Check features for the current user

When developing a feature, enabled features for a user can be checked as follows.

``` ruby
if current_user.feature?('feature_name')
  # Execute logic...
end
```

When running code in other services, such as in a cron job or background job and not for of spcific user, it may be necessary to check whether a feature is enabled for the platform.
In this case, the anonymous session can be used to check for the status of the feature for all users:

``` ruby
Xikolo.api(:account).value!
      .rel(:session).get(id: 'anonymous', embed: 'features').value!

=> {"id"=>nil,
    "self_url"=>"http://localhost:3100/sessions/anonymous",
    "user_id"=>"02e4fdd9-23f3-45f5-ba45-95cbc41c42f0",
    "user_url"=>"http://localhost:3100/users/02e4fdd9-23f3-45f5-ba45-95cbc41c42f0",
    "user_agent"=>nil,
    "masqueraded"=>false,
    "interrupt"=>false,
    "interrupts"=>[],
    "features"=>{"for_everyone"=>"t"}}
```

### Disable features

If you want to disable a specific feature that has been previously enabled, the corresponding `Feature` record needs to be destroyed.

``` ruby
Feature.find_by!(name: 'feature_name', owner: User.find(user_id)).destroy!
```

## Best practices

1. Regularly review enabled features.
2. Test new features before enabling them for all users.
3. Maintain documentation of changes.
