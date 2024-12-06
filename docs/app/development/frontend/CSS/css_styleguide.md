# CSS Styleguide

This CSS Styleguide contains a set of standards and rules on how to write CSS code in Xikolo. Its purpose is to develop a more consistent and maintainable project.

## Linter

A CSS Linter is a tool that does basic syntax checking and applies a set of rules to help you write more efficient code. The rules we use in Xikolo are defined in the [stylelint standard config](https://github.com/stylelint/stylelint-config-standard) and extended by [these rules in the stylelint config](https://lab.xikolo.de/xikolo/web/blob/master/.stylelintrc.js).

At the moment, we choose to [ignore all files](https://lab.xikolo.de/xikolo/web/blob/master/.stylelintignore) that were created prior to defining this style guideline. Newly created files have to follow these rules and old code has to be refactored in the future and removed from the ignore list.

For the [video-player project](https://lab.xikolo.de/xikolo/video-player), we want to stick to the same linter rules. With the [exceptions](https://lab.xikolo.de/xikolo/video-player/blob/master/.eslintrc.json), we have to take into account to make sure the linter does not collide with the stencil tool we are using. The same project rules apply.

## Project rules

Rules listed here cannot be enforced by a linter. Nevertheless, these rules should always be applied.  If an exception is required, the reason should be commented on in the code.

### Use BEM notation

BEM stands for Block Element Modifier and is an HTML & CSS naming methodology that helps you create reusable components and aids code sharing in front-end development. You can find more information on [getbem.com](http://getbem.com/introduction/).

!!!example

    ```scss
    .btn {
      color: $gray;

      &--open {
        color: $green;
      }

      &--close {
        color: $red;
      }

      &__icon {
        border: none;

        &--open {
            border: 2px solid $green;
        }

        &--close {
            border: 2px solid $red;
        }
      }
    }
    ```

### Use tables of contents and section blocks

Sections divide the file into multiple parts. To have a good overview of all the sections whithin a file we add a table of contents at the beginning.

!!!example

    ```scss
    //------------------------------------
    // $CONTENTS
    //
    // The file header gives a short description of the content found in the file.
    //------------------------------------
    /**
    * Variables..............Variable declarations and overrides
    * Bootstrap-Import.......Bootstrap import
    */
    //------------------------------------
    // $Variables
    //------------------------------------
    $navbar-border-radius: 0px;
    $navbar-margin-bottom: 0px;
    //------------------------------------
    // $Bootstrap-Import
    //------------------------------------
    @import "twitter/bootstrap/navbar";
    ```

### Use American English spelling

Use color instead of colour.

### Use fully-qualified variables for every color

!!!example

    ```scss
    //DO THIS
    color: $white;

    //DON'T DO THIS
    color: #fff;
    ```

### Use .scss

Use .scss syntax (Sassy CSS) instead of the older sass syntax.

!!!example

    ```scss
    // DO THIS
    .content-navigation {
      border-color: $primary-color;
      color: $primary-600;
    }

    // DON'T DO THIS
    .content-navigation
      border-color: $primary-color;
      color: $primary-600;
    ```

### Use our own helper methods

Instead of using bootstrap helper methods, create your own helper method. We want to be as independent of bootstrap as possible. If you encounter a bootstrap helper, write it new. Helper methods are located in `app/assets/stylesheets/partials/_utility.scss`

!!!example

    ```scss
    .text-truncate {
      text-overflow: ellipsis;
      overflow: hidden;
      white-space: nowrap;
    }
    ```

### Colors

Use colors and shades predefined in the color scheme. Please extend the scheme if a new color is needed. Do not add colors randomly or overuse CSS preprocessor functions like “lighten” or “darken” to create shades on the fly.

### Declaration order

Related property declarations should be grouped together following the order:

1. Positioning
2. Box model
3. Typographic
4. Visual
5. Misc

<details>
  <summary>See example</summary>

  ```scss
    .declaration-order {
      /* Positioning */
      position: absolute;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      z-index: 100;

      /* Box-model */
      display: block;
      float: right;
      width: 100px;
      height: 100px;

      /* Typography */
      font: normal 13px "Helvetica Neue", sans-serif;
      line-height: 1.5;
      color: #333;
      text-align: center;

      /* Visual */
      background-color: $white;
      border: 1px solid $gray;
      border-radius: 3px;

      /* Misc */
      opacity: 1;
    }
  ```

</details>

## Best practices

As a team, we have agreed on certain best practices. They are intended to help us write cleaner code that is more maintainable.

### Comment your code

Since CSS code can hardly be optimized for readability, comments are fine.
Comments should go above the CSS code they belongs to:

!!!example

    ```scss
    // this explains the rule
    .complicated-rule {
        ...
    }

    .block {
      not-complicated: true;
      // this explains the rule
      complicated: true;
    }
    ```

### Avoid fixed widths

Try to avoid fixed widths as much as possible.

!!!example

    ```scss
    // DO THIS
    width: 80%;

    // DON'T DO THIS
    width: 500px;
    ```

### Avoid magic numbers

Try to avoid magic numbers and use variables if possible. If there has to be a magic number, comment on it.

!!!example

    ```scss
    // BAD
    padding: 23px;

    // BETTER
    // override for off looking brand specific stuff
    padding: 23px;

    // BEST
    padding: 2 * $md-size;
    ```

### Relative vs absloute units

Use **px** for fixed sizes.

[Google developers recommend](https://web.dev/accessible-responsive-design/) using **rem/em** for text sizing. *Rem* units will scale with the root font size (`16px` by default) so it's a good practice to use them also for all other elements you want to be scaled when the user increases the browser font size. Users can change this value for accessibility reasons. A study conducted by the Internet Archive found that these users account for about [3%](https://medium.com/@vamptvo/pixels-vs-ems-users-do-change-font-size-5cfb20831773) on their page.

**em** units scale with their parent font size (instead of root); be careful, *em* cascades, which can lead to unintended results if a child element of a child element also increases the value.

### Mobile first

Writing mobile-first CSS helps to simplify the code, since most of the time, we can rely on default properties to style content for smaller screens.
It also enforces taking responsive design into account. It's ensured the page is properly displayed on a small screen and scales up.

!!!example

    ```scss
    // DO THIS
    .content {
      // Properties for smaller screens.
      // Nothing is required here because we can use the default styles

      // Properties for larger screens (uses the min-width media query from the small custom mixin (see grid-settings.scss)).
      @include small {
        float: left;
        width: 60%;
      }
    }

    // DON'T DO THIS
    .content {
      // Properties for larger screens.
      float: left;
      width: 60%;

      // Properties for smaller screens (uses the max-width media query from the deprecated sm custom mixin (see grid-settings.scss)).
      // Note that we have to write two default properties to make the layout work
      @include sm {
        float: none;
        width: 100%;
      }
    }
    ```

### Refactor first

If you run into a CSS problem, try reducing the code before you start adding more in a bid to fix it.
Chances are that it could be refactored first to simplify the final result.

### Don't over-qualify selectors

Try to keep selectors to a minimum specificity.

!!!example

    ```scss
    // DO THIS (Give yourself the class you need)
    .section-header {
      /* normal styles */
    }

    .about-section-header {
      /* override with same specificity */
      /* possibly extend the standard class */
    }

    // DON'T DO THIS
    .section-header {
      /* normal styles */
    }

    body.about-page .section-header {
      /* override with higher specificity */
    ```
    Example from [css-tricks](https://css-tricks.com/strategies-keeping-css-specificity-low/)

### Use ID only in exceptions

As a general rule, we shouldn't use IDs to style elements.

Use it only with elements that you are certain that appear only once on the page (header, footer) or when specificity needs to be increased.

### Use SCSS mixins and functions

To fully leverage SASS, we use mixins and function definitions to ease cumbersome or problematic CSS syntax.

Some helpers improve the handling of the DRY principle as well for CSS/SASS.

The mixins include:

- Vendor-specific-prefix mixins (to clean up the CSS)
- Robustness helpers (currently for font declarations)
- CSS snippets which are often needed and generic - these can be included with a single include statement, which doesn't clutter the code

Helper methods are located in `app/assets/stylesheets/modules/_helpers.scss`.

### Nesting

When to nest elements:

- For `:hover`, `:focus`, `::before`, and so on.
- For child components within a parent component (in the context of BEM).

Using BEM, nesting one level should be enough.

!!!example

    ```scss
    .PageIntro {
      ...

      &__title {
        ...
        }
    }
    ```
