# Reactivation

!!! note

    Allowing users to reactivate courses requires [vouchers](vouchers.md) to be enabled.

## Platform configuration

```yaml title="xikolo.yml"
course_reactivation:
  period: 8
```

!!! note

    `period` is the number of weeks for the reactivation period.

## Course configuration

With the enabled feature flipper, a course can be set to allow course reactivation in the "Certificates" section in the "Course Properties" in the course administration.

## Helpdesk configuration

The helpdesk will also show a new category for course reactivation for users with the feature flipper.
The corresponding locales need to be added to the (brand) locale file or set individually for a platform via configuration (`helpdesk`).
