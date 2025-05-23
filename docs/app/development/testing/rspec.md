# RSpec tests

RSpec is a testing tool for Ruby.
There are different types of RSpec tests that we use .
Some of the most important are:

- Feature specs (`spec/features`)
- Request specs (`spec/requests`)
- View specs (`spec/views`)
- Component specs (`spec/components`)

## Basic structure of an RSpec test

An RSpec test is composed of a number of nested blocks, starting with a `describe` block, which contains `context` and `it` blocks, which themselves contain the test code.
Here is an example:

```ruby
describe MyClass do
  describe "#method_name" do
    context "under a certain condition" do
      it "should do something" do
        # test code here
      end
    end

    context "under a different condition" do
      it "should do something else" do
        # test code here
      end
    end
  end
end
```

In this example, we are testing the behavior of a method called `method_name` in a class called `MyClass`.
We have two different context blocks, each containing a separate test that focuses on a different aspect of the method's behavior.

In general, you can think of `describe` as defining the "what" of a test, while `context` defines the "when" or "under what circumstances".
`describe` is used to group tests based on the feature being tested, while `context` is used to group tests based on the context or scenario being tested.

## Difference between `let` and `before`

`let` and `before` are both used in RSpec tests to set up the necessary state for each test.
The main difference between them is when they are evaluated.

- `let` is evaluated lazily, meaning that the code inside the `let` block is only executed when the variable is first accessed in a test.
This can help improve performance by avoiding unnecessary setup code.

- `before` is evaluated eagerly, meaning that the code inside the `before` block is executed before each test.
This can be useful for setting up common state that is used across multiple tests.

!!! note

    In addition to `let`, RSpec also provides a `let!` method.
    `let!` blocks are executed before each test, regardless of whether the variable is accessed, similar to `before` blocks.
    However you might need to use `let!` to predefine entities and reference them in tests, which can not be done with the `before` block.

In this example we are creating a variable `user` with the corresponding factory and the email trait.
To set up the test, we use the `before` block to create an `enrollement` for this user.

```.ruby
  let(:user) { create :user, :with_email }
  before do
    create :enrollment, :proctored, user_id: user.id, course: course
  end
```

!!! note

    Factories can be found in `spec/factories`.
    They are grouped by specific domains of our application (e.g., account, course, and video).

## Stubbing requests

"Stubbing" refers to the practice of replacing a method on an object with a predefined response.
As our application has a microservice architecture, we need to use stubbing very often.

In this example, we use `stub_user_request` to stub a user resource, `Stub.service()` to stub the course service, `Stub.request()` for stubbing a particular request to the course service, and `stub_request` to stub the call to S3.

```.ruby
  before do
    stub_user_request id: user.id

    Stub.service(:course, build('course:root'))
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    stub_request(:get, 'https://s3.xikolo.de/xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf')
      .to_return(body: File.new('spec/support/files/certificate/template.pdf'), status: 200)
  end
```

!!! note

    For more information, please take a look at our custom helper methods implementation (`/gems/xikolo-common/lib/xikolo/common/rspec/stub.rb`).

## Best practices for RSpec tests

- **Keep tests focused:** Each test should focus on one specific behavior or feature of the code being tested. This makes the tests easier both to read and understand. In addition, it also makes it easier to diagnose and fix issues when they arise.

- **Use descriptive test names:** Use descriptive names for your `describe` and `it` blocks. This makes it easier to understand what each test is doing and what it's testing. A good test name should be concise but descriptive. Try to abstract from the concrete implementation.

- **Write clear and concise tests:** Tests should be written in a way that is easy to read and understand. They should be concise and to the point, with as little repetition as possible. Use helper methods to keep tests DRY (Don't Repeat Yourself).

- **Use `let` and `before` blocks:** Use `let` blocks to define variables that are used throughout your tests.
Use `before` blocks to set up any necessary state before each test. This keeps your tests organized and reduces duplication.

- **Use stubbing only when necessary:** Overuse of this technique can make tests brittle and difficult to maintain.

- **Edge cases:** Be sure to test edge cases in addition to the more common cases. Test valid, edge and invalid case. This helps to ensure that your code is robust and handles unexpected situations correctly.

- **Keep your tests up-to-date:** As your code changes, be sure to update your tests to reflect those changes. This ensures that your tests remain accurate and effective.

## Resources

If you are not familiar with RSpec and its DSL syntax, you might want to study the following resources:

- [RSpec Official Page](https://rspec.info/)
- [Better Specs](https://www.betterspecs.org/)
- [Effective Testing With RSpec 3 by Myron Marston & Ian Dees](https://pragprog.com/titles/rspec3/effective-testing-with-rspec-3/)
- [Rspec style guide by Rubocop](https://github.com/rubocop/rspec-style-guide)
- [Some good example descriptions can be found here](https://www.tomdalling.com/blog/mentoring/write-detailed-rspec-example-descriptions/).
