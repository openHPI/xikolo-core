
# CSS

For a more elegant, DRY, and easy-to-maintain CSS code, we use the popular preprocessor, SASS.

## SCSS Architecture

Besides the global main entry point `main.scss`,
the majority of our CSS [is located here](https://lab.xikolo.de/xikolo/web/-/tree/master/app/assets/stylesheets).

It includes the following files and folders:

### Imports

- `global.scss`: Global import list
- `theme.scss`: Base style import list
- `components.scss`: Components import list
- `partials.scss`: Partials import list
- `libs.scss`: External library imports

### Styles

- `components`: For a maintainable SCSS code base, styles should be scoped to components if possible
- `partials`: Prior to transitioning to a component-based system, all individual SCSS partials for platform components were stored in this location.
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
    This architecture was inspired by [this guide](https://thesassway.com/how-to-structure-a-sass-project/)

## Bootstrap Integration

The gem `bootstrap-sass` integrates Bootstrap 3 in our application.

It provides all the individual bootstrap components, mixins, modules, etc.
In `app/assets/bootstrap-custom.scss` we import the parts that we need for the application.
It is build in a separate module and included in the layouts.

!!!note
    We import the assets again in the corresponding SASS partial where they are used.
    E.g `@import "bootstrap/dropdowns"` is called again in `app/assets/stylesheets/partials/_dropdown.scss`.
    This double import has developed over time and is not something we consider good architecture.

## File Anatomy

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
  @import "twitter/bootstrap/COMPONENT";
  //------------------------------------
```

### Sections

To organize a SCSS file into different sections use a dollar sign for uniqueness in search queries, as well as hyphen to delimit multiple words.

```scss
  //------------------------------------
  // $SECTION-TITLE
  //------------------------------------
```
