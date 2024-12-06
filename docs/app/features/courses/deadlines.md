# Deadlines

Many course content elements have deadlines affecting when and how users can interact with them. They should help users to organize their work (when content gets available) and avoid missing submissions. Such deadlines are represented by `NextDate` resources.

## Maintenance and recalculation

For now, all deadlines are managed automatically based on other course resources. This is done asynchronously in background jobs. In the future, other parts of the application might manage deadlines themselves.

The jobs are scheduled upon relevant changes of the corresponding resources (courses, sections, etc.). The job implementation must be idempotent and should create, update or delete deadlines based on the current resource attributes.

## The `NextDate` resource

All deadlines have a `type`, `date`, and `title`. Further attributes coordinate the processing:

- `resource_type` and `resource_id` reference the resource with a deadline (e.g. a course, section or item).
- The `course_id` represents the transitive relation to the course, to simplify filtering.
- `section_pos` and `item_pos` allow content-based ordering (tie-breaker when two deadlines are equal).

The remaining fields determine when and to whom the deadline is visible (`slot_id`, `user_id`, `visible_after`). They are explained in the next section.

## Visibility

`NextDate` resources represent actions that must be executed before a specific date. Once the action has been executed, this reminder should disappear. Many deadlines are identical for all users, but some might only be relevant for a specific group or require a precondition (like a submission). Moreover, their disappearance depends on whether and when users take action.

### General vs. user-specific

`NextDate` resources can be **general** (relevant to all users of a course) or **user-specific** (restricted to individual users). They are differentiated by the `user_id` attribute.

!!! note

    To satisfy PostgreSQL's `NOT NULL` constraint for primary keys, `00000000-0000-0000-0000-000000000000` (returned by PostgreSQL's `uuid_nil()` function) is stored as `user_id` to encode general `NextDate` resources.

### Slots

Corresponding general and user-specific `NextDate` resources must share the same `slot_id`. **User-specific deadlines trump their general counterpart.** For a given `slot_id`, a user-specific `NextDate` will always be preferred if it exists; otherwise, we fall back to a general `NextDate`. This selection is done at all times; other filters or checks are applied afterward.

Because slot IDs are shared, it is critical to deterministically generate them (to avoid complex query logic or additional state). This is solved using [version 5 UUIDs][uuid5]. These are statically derived from two parts:

- The resource ID is used as **namespace**. Deadlines for different resources are always independent.
- The **name** is usually the deadline's `type` identifier. A different value may be used to replace a general deadline with a different-but-related user-specific deadline. For example, `item_submission_deadline` and `item_submission_publishing` deadlines both use `item_submission` to derive the `slot_id` (so that a user sees either the submission deadline or the publishing date, but never both).

### Dates

The `visible_after` column can be used to hide deadlines until the referenced content resource is published. **Deadlines without `visible_after` are always visible.** A user-specific `NextDate` with a past `visible_after` date can be used to hide a general `NextDate` without (really) replacing it.

[uuid5]: https://en.wikipedia.org/wiki/Universally_unique_identifier#Versions_3_and_5_(namespace_name-based)
