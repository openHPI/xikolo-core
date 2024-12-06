# Testing

## Types of tests

We employ different types of tests to test the various layers of our system.
All of them have certain benefits and disadvantages.
Knowing these can help you choose the best type of test in a given scenario.

### Unit tests

Test _a single unit of code in isolation_ from other parts of the system.
Units can be single classes, but can also be a group of classes that belong together.
The tests should instantiate the object(s) and run assertions against the observable behavior of the unit's public API.
We typically create unit tests for UI components (`spec/components`), presenters (`spec/presenters`), or other library classes (`spec/lib`).
The bulk of the tests should be unit tests - here is where we define the behavior of our core abstractions and domain model.

**Strengths:**

- Easy to isolate.
- Fast, stable and _precise_.

**Weaknesses:**

- _No guarantee_ for correct behavior of the entire system, i.e. the integration of different components.

### Integration tests

Test _how different parts of the system work and interact_.
We often test Rails models (`spec/models`) in a way that's similar to unit tests - but as this involves actual database queries, these are closer to integration tests than unit tests.

**Strengths:**

- Crosses boundaries, which makes the tested use cases more realistic.

**Weaknesses:**

- Harder to isolate.

### Request tests

A special type of integration test covering _HTTP endpoints_ from the outside.
Choose a HTTP verb and a path, then test the HTTP response and potential side effects (e.g., database records being created).

**Strengths:**

- Not coupled to controllers / other layers, which make them particularly useful for more extensive refactoring.

**Weaknesses:**

- Test setup can be harder, e.g. for authentication.

### Feature tests

Test certain aspects / _pages of our application_ in a browser.
Requests to other services (for reading / writing data) need to be stubbed.

**Strengths:**

- Able to test real, interactive UI behavior, involving the browser.
- Faster than E2E tests or manual testing of these scenarios.

**Weaknesses:**

- Comparably expensive and slow tests, so request specs are preferred if suitable.
- Stubs can quickly become unrealistic or out of sync.

### End-to-end (E2E) tests

Test _real user behavior across all services_ by driving a browser with automated tests.
These actually start up all services!
It's good for testing the most important use cases for end users.
We often limit ourselves to "happy paths" and try to test edge cases in lower levels.
Scenarios are defined in `integration/features/xikolo`, which make use of the steps implemented in `integration/features/steps`.

**Strengths:**

- Very realistic scenarios covering complex application behavior.
- Can test real end-user scenarios.
- Can be written in a less technical way, using a DSL.

**Weaknesses:**

- Very expensive and slow tests.
- Often brittle (e.g. tests failing randomly because of race conditions).

## Characteristics of good tests

What makes a test good or useful?

Let's recap why we write tests:

- They provide documentation on how the application is expected to behave.
- Prevent against regressions (accidental bugs) when changing unrelated code.
- Ensure safe refactorings, i.e. internal changes to code without changing behavior.

Note that most of these become relevant when the code under test changes.
If code would not change, one manual test after finalizing the code would be enough.
In other words: tests are most useful when they fail.
This is the moment when they prove their usefulness, otherwise you would not need them.
Therefore, do not be afraid of failing tests, be thankful for them.

In the following, we collect heuristics that help us determine whether a new test is useful or "good" - based on the goals laid out above:

1. **The test is deterministic.**

    When running the test suite repeatedly in different orders, the test should always have the same result.
    The opposite is called a "flaky" test.
    Some factors that can make a test flaky or order-dependent are date/time, and shared state between tests.

2. **When the test fails, the code is broken.**

    This seems obvious, but must be emphasized. It is the most important property we desire from tests.

3. **When the code is broken, the test fails.**

    If a test is written in a way that it never fails, its value is diminished.
    The TDD cycle (writing tests before the code that makes them pass - "red-green-refactor") ensures this.
    Misleading green tests ("false positives") are worse than untested code.

4. **Intentional behavior changes require changes to the test.**

    Does a test fail when you change the code it's testing, e.g. by flipping a boolean or changing a magic number to another one?
    This ensures good coverage and can help code readers understand non-obvious aspects of code (the necessity of type-casts, conditions, etc.).
    Sometimes, it can be tempting to write tests in a way that changes to the code immediately reflect in the tests, without having to change them (e.g. adding new fields to an API serialization).
    However, if tests are supposed to document behavior, then of course changing behavior should require changes to the corresponding documentation / test.

5. **When you refactor the code under test, the test does not need to change.**

    This is another way of saying that the test only depends on the external (or public) interface of the unit under test, and not any implementation details.
    The test should not be coupled to the code it's testing.
    Only if we do not make any changes at all to the corresponding tests, we can have reasonable certainty that the code still behaves the same after refactoring.

## Test-driven development vs. Behaviour-driven development

First of all, test-driven development (TDD) is a development practice while behaviour-driven development (BDD) is a team methodology.
In TDD, the developers write the tests while in BDD the (often automated) specifications are (usually) created by users or testers (with developers wiring them to the code under test).
For small, co-located, developer-centric teams, TDD and BDD can become more or less the same when it comes to writing tests - but there is still a difference related to the strong focus on the system behavior in BDD.

### What is TDD?

TDD means using tests while writing code to validate what you are writing is correct, i.e. cover new functionality with tests before implementing the required logic.
This forces to think about the expected result of the implementation first, which also results in tests focusing on the actual use cases of the application instead of tests being tightly coupled to the implementation.

**What is it good for?**

- Good when refactoring code. Make sure the behavior for the (to be) refactored code is tested first.
- Good when bug fixing, as a regression test can ensure the bug will not happen again.

### What is BDD?

BDD results in tests that are more human-readable and more end-user / business-related.
BDD testing is a way of making tests replicate behaviour of a user and is more relatable for less tech-inclined folks.
Provided that the developers take care of the wiring underneath, this can be a very effective way for stakeholders to understand what is being tested.

BDD can be combined with the TDD approach.
The resulting specs tend to be executed using a headless browser, e.g. [E2E tests](end_to_end.md) with Capybara.

**What is it good for?**

- More suited to a higher-level perspective.
- Focuses on integration of services and UI aspects.
