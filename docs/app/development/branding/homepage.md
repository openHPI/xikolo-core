# Homepage

As the public entrypoint into the platform, the homepage often needs special customization.

Xikolo offers a few re-usable building blocks that can be used to easily build a custom homepage without much effort.

## Custom markup

If the homepage should be customized significantly for a brand, custom HTML markup may become necessary. The homepage is rendered by the `index` action of the `Home::HomeController`. If necessary, a branded template can be registered in the `CUSTOM_BRAND_TEMPLATES` array within the controller. Per convention, the template must then be named `app/views/home/home/index_<name>.html.slim`.

## Components

### Course categories

Highlighting current or popular courses is a common use-case for the platform homepage. To render a "category" of courses, e.g. based on start date or other forms of categorization, a brand needs to do the following:

- Register a custom "course loader" in an [initializer](initializers.md): this must be a callable object that returns an array of renderable components when called.
- In the template, loop over `@categories` and call `render` on them.

To make this easy, Xikolo provides the `Home::Category` component that can render any "category" object passed to it. Such a category must provide the methods `title`, `url` and `courses`. If the `url` method returns a truthy value, a button will show up and link to the given URL, e.g. the full course list. Xikolo also ships with three built-in categories that implement different ways of loading courses:

- `Catalog::Category::Channel` - Publicly visible courses from the given channel.
- `Catalog::Category::Classifier` - Publicly visible courses tagged with the given [classifier](../../features/courses/classifiers.md).
- `Catalog::Category::CurrentAndUpcoming` - Courses that are currently running or will start soon, ordered by start date.

Example:

```ruby
# brand/<name>/initializers/homepage.rb
Rails.application.config.homepage_course_loader = proc do
  # Load current and upcoming courses
  current_and_upcoming = ::Catalog::Category::CurrentAndUpcoming.new

  # Only show the category if it is not empty
  current_and_upcoming.courses.any? ? [::Home::Category.new(current_and_upcoming)] : []
end
```
