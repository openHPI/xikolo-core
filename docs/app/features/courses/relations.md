# Course relations

Course relations and the closely connected course sets are means to group courses and link those courses or course groups together.
The `Course` domain mainly holds the necessary data structure, while the interpretation of these connections are implemented in the context of other business logic.

## Use cases

### Course tracks & combined courses

"Course tracks" or alternatively "Combined courses" revolve around *course prerequisites*, where learners have to finish a set of courses before accessing the content of another course.

"Finishing a course" can either require the *Confirmation of Participation* or the *Record of Achievement* , based on the configuration (i.e., the kind of the respective course relation).
A prerequisite in a course can also be configured with a "one out of X" option, e.g. if you allow different iterations of a course as equal prerequisite candidates.

!!! example

    ![Course track example](course_tracks_example.png)

    Course X is a course with 3 requirements. To be able to enroll, a user needs

    - a Confirmation of Participation in Course A-1 **or** Course A-2
    - **and** a Confirmation of Participation in Course B
    - **and** a Record of Achievement in Course C

All of a course's prerequisites will be listed on the course's details page.

### Future use cases

- Language variants / translations of courses
- Course iterations (series)
- Recommended courses
- and more...

## Resources

Course Sets

:   A simple data structure identified by a name and holding a number of courses (*course set entries*) that "belong together" in the context of a course relation.

Course Relations (actually `CourseSetRelations`)

:   Define directed connections between course sets.
    They need a *source* and a *target set* as well as a *kind*.
    Course relations only work with course sets, not with single courses.
    Though, a course set can consist of only one course.

## Configuration

For the example above, course sets and relations can be configured via console as follows:

``` ruby
cs_a = CourseSet.create!(name: 'A')
cs_a.courses = Course.where(course_code: ['a-1', 'a-2'])

cs_b = CourseSet.create!(name: 'B')
cs_b.courses = Course.where(course_code: 'b')

cs_c = CourseSet.create!(name: 'C')
cs_c.courses = Course.where(course_code: 'c')

cs_x = CourseSet.create!(name: 'X')
cs_x.courses = Course.where(course_code: 'x')

CourseSetRelation.create!(source_set: cs_x, target_set: cs_a, kind: 'requires_cop')
CourseSetRelation.create!(source_set: cs_x, target_set: cs_b, kind: 'requires_cop')
CourseSetRelation.create!(source_set: cs_x, target_set: cs_c, kind: 'requires_roa')
```
