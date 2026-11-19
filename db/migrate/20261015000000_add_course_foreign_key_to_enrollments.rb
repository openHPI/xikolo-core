# frozen_string_literal: true

# Adds the missing foreign key from `enrollments` to `courses`.
#
# `enrollments.course_id` currently has no foreign key, so an enrollment can
# reference a course that no longer exists. The key is added with
# `validate: false` on purpose: existing (possibly orphaned) production data is
# not scanned or validated here, but the key starts enforcing referential
# integrity for new writes immediately.
#
# Once orphaned enrollments have been removed by hand, a follow-up migration
# should:
#   * make `course_id` non-null, and
#   * validate the key (`validate_foreign_key :enrollments, :courses`).
class AddCourseForeignKeyToEnrollments < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :enrollments, :courses, validate: false
  end
end
