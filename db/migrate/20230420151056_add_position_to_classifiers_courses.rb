# frozen_string_literal: true

class AddPositionToClassifiersCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :classifiers_courses, :position, :integer

    up_only do
      execute <<~SQL.squish
        UPDATE classifiers_courses
        SET position = mapping.new_position
        FROM (
         SELECT
           course_id,
           classifier_id,
           ROW_NUMBER() OVER (
             PARTITION BY course_id
             ORDER BY classifier_id
           ) as new_position
         FROM classifiers_courses
        ) AS mapping
        WHERE classifiers_courses.course_id = mapping.course_id
        AND classifiers_courses.classifier_id = mapping.classifier_id;
      SQL
    end
  end
end
