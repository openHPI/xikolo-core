# Database migrations

This section provides a brief overview of the most important aspects and focuses on specifics and best practices for the Xikolo project.

!!! note

    For detailed information on database migrations, please see the general [Rails guide](https://guides.rubyonrails.org/active_record_migrations.html).

## What are migrations used for?

- Used to alter the database (like adding, changing, or removing columns or tables) consistently over time.
- Used to alter the data ("data migrations").
- Build on each other like git commits.
- Performed migrations are saved to the *schema_migrations* table, recording the numbers of applied migrations.

## Production database

On production, migrations are usually not rolled back, e.g. as affected data could be easily lost.
Deleting or altering data types can only be reversed when the data is stored in a backup table upfront.
However, please avoid irreversible migrations as it's still helpful to rollback migrations locally.

!!! tip

    It's recommended to write a test and test the reversible migration before deploying it to production.

## Exemplary workflow for a data migration

Scenario: Add a dedicated `Visual` resource and fill it with data from `Course.visual_uri` and `Course.vimeo_id`.

1. Run the migration creating the new table. See the `20230208143700_create_course_visuals.rb` file.
2. Adapt the code to write to both data resources.
    - Old: `Course.visual_uri` / `Course.vimeo_id`
    - New: `Visual`
3. At the same time, run the migration for copying data from the old to the new resource. See the `20230209141046_migrate_course_attributes_to_course_visual.rb` file.

    !!! tip

        Beware: Data migrations might take very long and thus need to be written efficiently!

4. Adapt code to **only** read from and write to the new data resource (`Visual`), i.e. remove all usages of the old attributes.
5. Run the migration to remove the old attributes. See the `20230419123459_remove_deprecated_course_visual_attributes_from_courses.rb` file.

## Best practices

Mock the used models in the migration, as their names may change in the future and thus this migration wouldn't work anymore. Here's an example:

```ruby
    class MigrateCourseAttributesToCourseVisual < ActiveRecord::Migration[6.0]
      # ...

      class CourseVisual < ActiveRecord::Base
        belongs_to :course, class_name: 'Course'
      end

      # ...
    end
```

The following best practices contribute to a better performance when executing the migration:

- Use bulk table migrations `change_table :example, bulk: true do ...`.
- Process records in batches `examples.find_each(batch_size: 50) do ...` or `Model.in_batches do ...`.
  - Replace `.where(...).each` with `.find_each`.
- Drop indices beforehand and add them again afterward.
- Replace `.save!` with `.save(:validate => false)` or use `.update_attribute` (to skip validations when only updating one field).
  - Only do that if you're certain that the validation criteria are fulfilled!
- Where possible, use fewer AR objects in a loop and consider using plain SQL queries. Instantiating and later garbage collecting them takes CPU time and uses more memory.

## Migrations vs. rake tasks

- Migrations provide a history and stay in the code base.
- Rake tasks need to be run manually (on production machines) whereas migrations are performed automatically as part of the deployment process.
- Migrations are reversible (under certain circumstances).
- There are suitable use cases for choosing a rake task over a migration, e.g. for "one-off" tasks like cleaning up unreferenced resources.
