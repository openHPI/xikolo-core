# Course service

## Public API v2

Base endpoint (e.g. for restify): `/api/v2/course`; all following URLs are relative to this point

### Courses endpoint

`GET /courses`

Purpose: Returns all courses visible for the current user.

Variations:

- `GET /courses?embed=description`: include the course descriptions
- `GET /courses?embed=enrollments`: include enrollment information
- `GET /courses?embed=description,enrollment`: include both

Responses: currently only JSON arrays. Each array element is an object description one course.

Example:

```jsonc
[
  {
    "id": "421b5845-a0d0-4fac-ad29-2a29570e2504",
    "course_code": "imdb",
    "name": "In-Memory Data Management-Entwicklung",
    "teachers": "Prof. John Smith",
    "abstract": "This is a nice course about cool stuff",
    "image_url": "https://example.de/files/00d7dfff-bb1f-44db-8ae7-afc2e6a184c3?size=large",
    "language": "de",
    "description": "",
    "state": "preparation / announced / preview / active / self-paced / (closed) | external",
    "external_course_url": "https://example.com/courses/external", // if state = 'external'
    "channel": "enterprise",
    "classifiers": {
      "category": ["Business", "Workshop"]
    },
    "start_date": "2014-06-30T10:30:00Z", // is internal display_start_date
    "end_date": "2014-07-13T10:30:00Z", // ?
    "enrollment": {
      "visits": {
        "visited": 0,
        "total": 20,
        "percentage": 0
      },
      "points": {
        "achieved": 0,
        "maximal": 0,
        "percentage": null
      },
      "certificates": [
        {
          "confirmation_of_participatin_url": "http://confirmation_of_participation"
        }
      ],
      "completed": false,
      "confirmed": false // ?
    }
  }
]
```

Course field descriptions:

- `id` (UUID as string): unique UUID for this course (internal identifier)
- `course_code` (string): unique short title for this course - external identifier
- `name` (string): Human understandable name/title for this course
- `teachers` (string): Names of the people/teachers how are responsible for this course
- `abstract` (string): Short summary about the course and its topic
- `image_url` (URL as string): course image
- `language` (two-letter language code as string): The language the course is held in
- `description` (markdown as string): Full description of the course, its topic, content of table (sections ...)
- `state` (`"preparation"` / `"announced"` / `"preview"` / `"active"` / `"self-paced"` / `"closed"` | `"external"`): the current life-cycle state of the course (in order. Most important are `active` between display_start_date and end_date and `self-pace` afterwards)
- `external_course_url` (URL as string): External entry point to reference the course
- `channel` (`null` or string): channel/track name
- `classifier` (object of arrays): for multiple types (here only `category`) the attached values for this type
- `start_date` (date as string (format?)): the official course start (means first section with content is opened)
- `end_date` (date as string (format)?): the official course end date (meaning no further content will be ended ...)
- `enrollment` (`null`, an enrollment object as described in the next paragraph): information about the user enrollment for this course if existing; `false` means the user cannot enroll themselves

Enrollment field descriptions:

- `visits`: TODO
- `points`: TODO
- `completed` (boolean): is the course/enrollment finished (like got a certificate)
- `confirmed` (boolean): user requested an enrollment, but it was not yet granted (planed)

### Course endpoint

`GET /courses/{course}`

Returns information about a specific course. Returns 404 if no such course is found. The return JSON objects matching the one of the courses' endpoint, please look their for a full description.

The `course` URL placeholder can be a course UUID like `"421b5845-a0d0-4fac-ad29-2a29570e2504"`, the UUID in compact encoded like `20JZojgX0SdfFQmjzg1RVa`, or the course_code like `imdb`

### Enrollment creation endpoint

`POST /courses/{course}/enrollment`

The possible formats for the `course` placeholder are described under "Course endpoint".

### Enrollment update endpoint

`PATCH /courses/{course}/enrollment`

The possible formats for the `course` placeholder are described under "Course endpoint".

Patch data should be a JSON object.

The current attribute can be changed:

`completed` (boolean): mark a course/enrollment as completed or not (overrides auto-decision)

### Enrollment destroy endpoint (unroll)

`DELETE /courses/{course}/enrollment`

The possible formats for the `course` placeholder are described under "Course endpoint".

No further data needed.

### Get stats per classifier

```ruby
years = (2013..DateTime.now.year).to_a
cf = Classifier.all.select { |c| c.title.start_with?('dim_') }

cf.each do |c|
  years.each do |year|
    course_ids = Course.from('embed_courses AS courses').not_deleted.where('hstore(\'id\', ?) <@ ANY(fixed_classifiers)', c.id).select(:id)

    count = Enrollment.unscoped.where(course_id: course_ids).where('extract(year  from created_at) = ?', year).pluck(:user_id).uniq.count

    uniq_count = Enrollment.unscoped.where(course_id: course_ids).where('extract(year  from created_at) = ?', year).count

    puts("#{c.title};#{year};#{count};#{uniq_count};")
  end

  count = Enrollment.unscoped.where(course_id: course_ids).pluck(:user_id).uniq.count

  uniq_count = Enrollment.unscoped.where(course_id: course_ids).count

  puts("#{c.title};all_time;#{count};#{uniq_count};")
end
```
