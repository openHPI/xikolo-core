# Stylesheets

## Root

You will need a `assets/main.scss` which imports the other files.

```scss
@import "stylesheets/theme";
@import "stylesheets/global";

@import "stylesheets/extensions/..."; // (1)
```

1. Extensions are optional.

Add a `theme.scss` that imports all of these files:

```scss
@import "stylesheets/theme/colors";

// Color schema definition
@import "stylesheets/theme/color_schema";

// Variables, mixins, and function declarations
@import "stylesheets/theme/common/variables";
@import "stylesheets/theme/common/helpers";

// Extracted common design parts for easier reusability and change
@import "stylesheets/theme/design";
```

Most of the important styles can be changed just by overriding SCSS variables in this file.
They will be described in more detail in the following section.

## Theme

### Colors

All base colors go into `_colors.scss`.
This will provide all color values that are needed for the application.
The file also contains all shades for these colors.

!!! note

    This file  overrides `app/assets/stylesheets/_colors.scss`.
    So you need to have at least all variables of `app/assets/stylesheets/_colors.scss` defined here.

#### Naming convention

- Use numbers after the color name, e.g. `primary-500`, for shades.
- Name custom variables with a `brandname-` prefix.

### Color Schema

In `color_schema.scss` we map colors defined in `colors.scss` to SCSS variables that are used in the application code.

Most likely, you have to adjust the three main colors:

- `$primary-color`
- `$secondary-color`
- `$tertiary-color`

!!! note
    Remember that you defined the shades in `_colors.scss`?
    A convention is to have the `500` shade as the main color: `$primary-color: $primary-color-500;`.

## Extensions

Some parts of the application can not easily be adjusted via simple SCSS variable override.
If you need more customization, `/extensions` is the place where you add a file with the same name as the `app/assets/stylesheets/partial` you want to extend.

List all the extension files as `@import` in the `main.scss`.

!!! example
    If you want to customize the `app/assets/stylesheets/partial/_navigation.scss` styles, add a `_navigation.scss` in the `extensions` folder.

### Design

Copy and paste the `/app/assets/stylesheets/theme/_design.scss` even if you don't need to make changes here.
This is a bit inconvenient, but the application does not work otherwise at the moment.
