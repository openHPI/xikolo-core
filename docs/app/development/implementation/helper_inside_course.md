# The helper method `inside_course`

You may already have noticed that the course-related pages have a specific layout with a dedicated navigation bar, including items for displaying learning resources, showing the learner's progress, displaying course announcements, and more.

Code-wise this is realized using the helper method `inside_course` in course-related controllers, where you would add all the `before_action` and other callbacks.

## Where does it come from?

The `inside_course` is a method defined in the `CourseContextHelper`.

```ruby
  # app/helpers/course_context_helper.rb
  def inside_course(**opts)
    layout 'course_area', **opts
    before_action :check_course_eligibility, **opts
  end
```

First of all, it overrides the default layout with a course-specific layout called `course_area`.
Additionally, it defines a `before_action` callback: `check_course_eligibility`.

```ruby
  # app/helpers/course_context_helper.rb
  def check_course_eligibility
    return if current_user.allowed?('course.content.access')

    if !the_course.was_available?
      unless the_course.published?
        Rails.logger.debug 'NOT FOUND: course not published'
        raise Status::NotFound
      end

      raise Status::Redirect.new 'course not started yet', course_url(the_course.course_code)
    elsif current_user.anonymous?
      store_location
      add_flash_message :error, t(:'flash.error.login_to_proceed')
      raise Status::Redirect.new 'user not logged in', course_url(the_course.course_code)
    else
      unless current_user.allowed?('course.content.access.available')
        add_flash_message :error, I18n.t(:'flash.error.not_enrolled')
        raise Status::Redirect.new 'user has no enrollment', course_url(the_course.course_code)
      end
    end
  end
```

This method is checking the permissions of the current user:

If the logged-in user has full access to the courses' contents, i.e. if the current user is a (course) admin, this check will not raise an error ("the user is eligible to enter the course").

If the user is a regular user and therefore does not have the `course.content.access` permission, it proceeds in checking the following scenarios concerning the course.
The course is available via the shared promise `the_course`, which is a `Xikolo::Course::Course` object (Acfs resource).

### The course is not yet published

```ruby
  if !the_course.was_available?
    unless the_course.published?
      Rails.logger.debug 'NOT FOUND: course not published'
      raise Status::NotFound
    end
    # ...
  end
```

In the condition, `the_course.was_available?` checks the course start date in the following manner:

```ruby
  # clients/xikolo-course/lib/xikolo/course/course.rb
  def was_available?(startdate = start_date)
    published? && (startdate.nil? || startdate < Time.zone.now)
  end
```

In natural language, this can be understood as:

```ruby
# The course has been published without a specific start date, i.e. is available.
published? && startdate.nil?
```

```ruby
# The course was available, starting at some date in the past.
published? && (startdate < Time.zone.now)
```

In its negative form - the `the_course.was_available?` is called with a bang here - this means the following:

```ruby
# Given that the course has not been published yet in any form
# (without start date OR its start date is in the future):
if !the_course.was_available?
```

```ruby
# If the reason is that the course has not been published,
unless the_course.published?
```

```ruby
# log a 'NOT FOUND: course not published' message
Rails.logger.debug 'NOT FOUND: course not published'
```

```ruby
# and raise a `Status::NotFound` error, since accessing the course is not yet allowed.
raise Status::NotFound
```

```ruby
# Otherwise, it will redirect to the course details page,
# with the error message that the course has not yet started (since the
# start date is in the future).
raise Status::Redirect.new 'course not started yet', course_url(the_course.course_code)
```

### The current user is not logged in

If the user is not logged in, it is redirected to the course page with an error flash message requesting the user to sign in.

```ruby
  # ...
  elsif current_user.anonymous?
    store_location
    add_flash_message :error, t(:'flash.error.login_to_proceed')
    raise Status::Redirect.new 'user not logged in', course_url(the_course.course_code)
```

### All other cases

```ruby
# If the user does not have permission to access the available content of the
# course (i.e., as a regular course student enrolled in the course),
unless current_user.allowed?('course.content.access.available')
```

```ruby
# an error message is flashed saying that the user is not enrolled
add_flash_message :error, I18n.t(:'flash.error.not_enrolled')
```

```ruby
# and the user is redirected to the course page.
raise Status::Redirect.new 'user has no enrollment', course_url(the_course.course_code)
```

## The `before_action` callback

Now that we know what `check_course_eligibility` is doing in detail, it's important to mention that this check is called as a `before_action` callback.

Typically, `before_action` callbacks are used to execute some logic before a controller action.
[Check the Rails guide for more details.](https://api.rubyonrails.org/classes/AbstractController/Callbacks.html)

Controller callbacks take some options, usually indicating for which actions their logic should or should not be executed (with the options `only:` or `except:`).

### A practical example

For example, the `Admin::CoursesController` defines `inside_course only: [:edit]`.

The `opts` of `inside_course` is defined as `only: [:edit]`.
When executing `inside_course`, the `opts` argument is passed to `before_action :check_course_eligibility`, so that the latter will be evaluated as `before_action :check_course_eligibility, only: [:edit]`.

This means that `check_course_eligibility` will be called for the `edit` action of the `Admin::CoursesController` only.

The course edit page is only shown for admins, i.e. for users having full access to courses.
`inside_course` sets the `layout 'course_area', opts`, e.g. showing the course navigation bar, only for the edit page.
For the `index` page, the course navigation bar is not shown.

## Testing

When testing logic that involves a controller using `inside_course`, you will always need to keep in mind stubbing the respective permissions for the current user.
For example, you will need to add the `course.content.access` to the stubbed permissions if it is a (course) admin.

## Similar methods

Just like `inside_course`, we also have `inside_item` (defined in the `ItemContextHelper`).
Its logic is very similar to `inside_course`: it overrides the default layout with a specific one for the course items and adds additional callbacks.
