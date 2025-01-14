# JavaScript styleguide

This page contains a set of standards and rules on how to write JavaScript code in Xikolo.
Its purpose is to develop a more consistent and maintainable project.

## Project rules

### Use data-attributes for JS hooks or Ruby controller properties

We consider it best practice to use data-attributes if there is a chance to generalize and reuse the code.

- `data-id` to target a specific element
- `data-behavior` for reusable hooks / sprinkles
- `data-controller` is useful if you want to encapsulate complex behavior to a component

It might be possible that certain elements require several `data-attributes` to function.
These should be a whitespace-separated list of words in the markup.
Be sure to use the `[~]` [attribute selector](https://developer.mozilla.org/en-US/docs/Web/CSS/Attribute_selectors#attrvalue_2) to attach the behavior in JS.

A nice reference can be found on this [css-tricks guide](https://css-tricks.com/a-complete-guide-to-data-attributes/).

**Why not use `id`?**

An `id` must be unique in the whole document.
Using `id` limits you to use the code only once at that specific place.

**Why not use js-prefixed classes?**

Classes should only be used for styling with CSS.
The use of js-prefixed classes clutters the class attributes.

### jQuery is deprecated

In Webpack (modern JS) assets, you can consider it forbidden.
Typical usage patterns for DOM traversal / manipulation can be [replaced with vanilla JS](http://youmightnotneedjquery.com/).

!!! info

    When you need to use a jQuery plugin, the global jQuery instance can still be used.
    This should be wrapped in dedicated modules, when possible, to restrict jQuery usages to as few places as possible.

    ```javascript
    const $ = jQuery;
    $(el).nameOfThePlugin(...);
    ```

### Avoid toggling classes with JS

Avoid toggling CSS classes with JS in favor of properties, data attributes, and ARIA attributes.
CSS rules based on them will apply the styling.

!!! example

    E.g. `hidden`, `readonly`, `disabled`, `aria-expanded`

### Content-dependent styling

For content-dependent styling (e.g. generated with JSON in JS), use data attributes instead of concatenated CSS classes

Make it clear in the stylesheet that the element matching the selector is dynamically annotated.
We want to avoid concatenating class names so that usages of CSS classes in stylesheets can always be found when searching across the whole codebase.

### File naming convention

As a file naming convention, we use kebab-case in our code base. E.g. `kebab-script.ts`.

## TypeScript

### Use TypeScript for newly added scripts

When adding new files to this project, consider using TypeScript for enhanced development and maintainability benefits:

#### Type Safety

TypeScript provides static typing, allowing early detection of potential bugs during development.
This reduces debugging time.

#### Code Maintainability

The presence of types and clear interfaces in TypeScript aids in understanding the expected shape of data and function parameters.
It makes the codebase more readable.

#### Improved IDE Support

TypeScript enhances development experience with features like intelligent code completion, refactoring tools, and better code navigation.
This can lead to increased productivity.

To start using TypeScript in a new file, simply create a `.ts` file.
A [useful guide to get started](https://www.typescriptlang.org/docs/handbook/typescript-in-5-minutes.html) can be found on the official page.

### TypeScript best practices

#### Interfaces vs. Types

As a general rule of thumb, use Types for straightforward type definitions.
E.g. defining simple data structures or for creating aliases for primitive types.

```typescript
type Location = {
    x: number;
    y: number;
｝；
```

When it comes to classes and extending functionalities, turn to Interfaces.

```typescript
interface Manager extends Employee {
  teamSize: number;
}

const manager: Manager = {
  name: 'Bob',
  role: 'Engineering Manager',
  salary: 100000,
  teamSize: 10,
};

```

If you are unsure, you can use the official [TypeScript cheat sheets](https://www.typescriptlang.org/cheatsheets) as a resource.
