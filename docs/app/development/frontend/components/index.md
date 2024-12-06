# Components

Client-side web frameworks, like Angular and React, have popularized "components" as a means of composing HTML interfaces from smaller parts.
Until recently, this approach was not as popular or widespread when rendering on the server-side.
Communities around server-side frameworks like Laravel or Ruby on Rails are beginning to pick up these concepts as well.

As the hipster kids we are, we already started doing this before it was cool. 😎

After starting with a home-grown solution, we later switched to the matured and now widespread [ViewComponent library by GitHub](https://github.com/github/view_component).

## Purpose

By default, Rails suggests structuring your views into [partials](https://guides.rubyonrails.org/v6.0/layouts_and_rendering.html#using-partials).
They help keep the file size under control, and when you want to re-use certain snippets of HTML.
However, they do not help you in keeping logic (e.g. business rules) out of your templates.
By itself, Rails does not suggest any mechanism to deal with this.
In many Rails projects, an additional "presenter" layer is introduced to implement the view-specific logic.

Building on these established patterns, components combine the small templates from partials and the presentation-specific code from presenters into one cohesive unit.

Therefore, when dealing with components, you have a named unit consisting of a dynamic HTML snippet combined with the logic and rules to render it.

!!! info "In other words"

    The fine folks at GitHub also [explained this well](https://github.blog/2020-12-15-encapsulating-ruby-on-rails-views/) when they announced their ViewComponent library.

## Usage

What follows is only a short primer on ViewComponent basics.
Do check out the extensive [ViewComponent guide](https://viewcomponent.org/guide/) to learn more about the library and its features!

### Defining a component

A component consists of two files:

* a **component class** defining the public interface of the component - it stores state (constructor arguments) and holds the logic to determine values needed for rendering the template
* a **Slim template** that takes the internal state and calls methods in order to generate HTML

The class for a very simple component could look like this:

!!!example

    ```ruby title="app/components/say_hello_with_time.rb"
    ##
    # Greet users by name and give them the current time
    #
    class SayHelloWithTime < ApplicationComponent
      ##
      # A plain Ruby class initializer. It defines the required (and optional)
      # input for rendering a component instance. Both positional and named
      # arguments can be used.
      #
      def initialize(name)
        @name = name
      end

      private

      ##
      # The "presenter logic" can live in private methods of the component
      # class. Here, the input (instance variables) can be turned into
      # something useful for rendering.
      #
      def now
        DateTime.now.strftime('%H:%I')
      end
    end
    ```

The corresponding template could then look like this:

!!!example

    ```slim title="app/components/say_hello_with_time.html.slim"
    p = "Hello, dear #{@name}!"
    p = "The current time is #{now}."
    ```

The template is evaluated within the context of the component class.
Both instance variables like `@name` and (private) methods like `now` can be accessed directly.

!!! note

    The template is co-located with its class, in the same directory.

### Rendering a component

The above component can be rendered in any Rails template (and even in a controller!) using the `render` helper:

!!!example

    ```slim title="app/views/layouts/_header.html.slim"
    = render SayHelloWithTime.new('Claus')
    ```

## Previews

We use [lookbook](https://github.com/allmarkedup/lookbook) to catalog, document and preview the different variants of our components.
This serves as our living style guide for UI components.

When developing, the lookbook UI is available at <http://localhost:3000/rails/components>.

Like templates, component previews are co-located with the component class.
Define a preview class with (at least) one action - et voilà: The previews will be automatically detected and picked up by lookbook.

!!! example

    ```ruby title="app/components/say_hello_with_time_preview.rb"
    class SayHelloWithTimePreview < ViewComponent::Preview
      def default
        render SayHelloWithTimePreview.new('Grace')
      end
    end
    ```

## Testing

Because components are limited in size and self-contained, they can be unit-tested very nicely:

!!!example

    ```ruby title="spec/components/say_hello_with_time_spec.rb"
    RSpec.describe SayHelloWithTime, type: :component do
      subject(:component) do
        described_class.new 'Claus'
      end

      it 'greets the user by name' do
        render_inline(component)

        expect(rendered_content).to have_content 'Hello, dear Claus'
      end
    end
    ```

ViewComponent offers some useful [test helpers](https://viewcomponent.org/guide/testing.html#rspec-configuration) and wraps the rendered HTML in a Capybara fragment to offer useful assertions (`#have_content`, `#have_selector`, ...).

Component tests should run assertions against the rendered HTML, and describe how that HTML changes when the input changes.

!!! tip

    Even though it may have other public methods, do not run assertions against those public methods.
    Those are just implementation details.
    The only public interface of components is their initialization with constructor arguments (the input) and the final HTML generated by `#call` or the template (the output).

    [More tips straight from the horse's mouth.](https://viewcomponent.org/viewcomponents-in-practice.html)
