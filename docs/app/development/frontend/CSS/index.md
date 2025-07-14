
# CSS

For a more elegant, DRY, and easy-to-maintain CSS code, we use the popular preprocessor, SASS.

## SCSS Architecture

Besides the global main entry point `main.scss`,
the majority of our CSS [is located here](https://gitlab.hpi.de/openhpi/xikolo/web/-/tree/master/app/assets/stylesheets).

It includes the following files and folders:

### Imports

- `global.scss`: Global import list
- `theme.scss`: Base style import list
- `components.scss`: Components import list
- `partials.scss`: Partials import list
- `libs.scss`: External library imports

### Styles

- `components`: For a maintainable SCSS code base, styles should be scoped to components if possible
- `partials`: Prior to transitioning to a component-based system, all individual SCSS partials for platform components were stored in this location (legacy).
- `bs-variables`: We aim to progressively reduce our dependence on Bootstrap. This file contains the necessary variables we extract from Bootstrap.

- `theme/`
  - `color_schema.scss`: Color schema variables
  - `colors.scss`: Includes all used colors
  - `design.scss`: Includes all common used mixins like bars, circles, underlines
  - `common/`:
    - `helpers.scss`: SASS Mixins and function declarations for usage throughout the site
    - `variables.scss`: Variable declarations

- `grid-setting.scss`: Breakpoints definition
- `xui`: Styles for the upload, download and pop up modules
- `controllers`: Legacy SASS styles for controllers

!!!note
    This architecture was inspired by [this guide](https://web.archive.org/web/20240128141859/https://thesassway.com/how-to-structure-a-sass-project/).

## Bootstrap Integration

We used to integrate Bootstrap 3 in our application using the [gem `bootstrap-sass`](https://github.com/twbs/bootstrap-sass).
This gem is no longer maintained and Bootstrap 3 is heavily outdated.

Global built-in functions are deprecated and will be removed in Dart Sass 3.0.0.
So in the near future, we need to [remove the `@import` directive from all our stylesheets](https://sass-lang.com/documentation/breaking-changes/import/).

Even the [up-to-date versions of Bootstrap makes it impossible to adapt SCSS modules](https://github.com/twbs/bootstrap/issues/29853).
An update to a future Bootstrap version seems not feasible due to the large number of breaking changes
and the fact that we have already started migrating to a self-made component-based SCSS architecture.

In conclusion, we want to use SCSS modules for our components, we are in the process of removing the dependency on Bootstrap.

### Phased Migration Approach

1) Audit all views to identify which Bootstrap components you actually use (done)
2) Create replacements for only those components, remove all unused Bootstrap components (done)
3) Rewrite existing components to use the new replacements (planned)

### Current Status

- `app/assets/stylesheets/components` is already "clean" and does not depend on Bootstrap. Do not add new Bootstrap code to it.
- `app/assets/stylesheets/partials` still contains a lot of Bootstrap code, and is considered legacy code. We can still adapt this code for fixes, but we should not add new Bootstrap code to it.
- New UI should always be implemented in the `components` folder, using the new component-based architecture.

### Future Considerations

For an upcoming redesign of the platform, we should migrate more towards the component-based architecture and eventually remove all Bootstrap code from the `partials` folder.
**Note**: As we have a compontent-based architecture, we can also consider using other CSS frameworks, such as [Tailwind CSS](https://tailwindcss.com/).

## File Anatomy for partials (legacy)

Almost all SASS partials follow the following template, which slightly varies depending on whether Bootstrap components are included.

### File Header

The file header gives a brief description of its content.
A table of contents follows, making it easy to find specific parts in a large file.

```scss
//------------------------------------
// $CONTENTS
//
// SHORT DESCRIPTION
//------------------------------------
/**
* Variables..............Variable declarations and overrides
* Additional points .....Short description
*/
```

### Variables

Variable declarations and especially Bootstrap overrides come before the bootstrap import.
Otherwise the override would not take effect.

```scss
  // $Variables
  //------------------------------------
  Variables definitions and overrides

  //------------------------------------
  // $Bootstrap-Import
  //------------------------------------
  @import "bootstrap/COMPONENT";
  //------------------------------------
```

### Sections

To organize a SCSS file into different sections use a dollar sign for uniqueness in search queries, as well as hyphen to delimit multiple words.

```scss
  //------------------------------------
  // $SECTION-TITLE
  //------------------------------------
```
