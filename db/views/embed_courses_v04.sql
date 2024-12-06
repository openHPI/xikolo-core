SELECT
  ARRAY(
    SELECT hstore(classifiers)
    FROM classifiers_courses
    INNER JOIN classifiers ON classifiers_courses.classifier_id = classifiers.id
    WHERE classifiers_courses.course_id = courses.id
  ) AS fixed_classifiers,
  COALESCE(
    alternative_teacher_text,
    array_to_string(
      ARRAY(
        SELECT name
        FROM teachers
        WHERE teachers.id = ANY(teacher_ids)
        ORDER BY (
          SELECT pos
          FROM (
            SELECT id, generate_subscripts(teacher_ids, 1) AS pos, teacher_ids
            FROM courses
          ) AS c
          WHERE courses.id = c.id
            AND teachers.id = c.teacher_ids[pos]
        )
      ),
      ', '
    )
  ) AS teacher_text,
  courses.*
FROM courses;
