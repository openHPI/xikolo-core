# Webpack bundles

## Webpack setup

The Webpack configuration files are located `config/assets`.
The `entries.js` contains a list of all Webpack modules to include the module-specific config files.
New modules can be registered here.

The `webpack*.js` files contain the configurations for the environment-specific config files for the Webpack asset pipeline.
These files only need to be touched when the pipeline changes and should not be changed by developers but rather by DevOps.

Usually, it is sufficient to add your changes to the respective module.

## Modules

We are still in the process of modularizing xi-web.
The following modules have been agreed on:

- **main**: for small, shared functions and initializers
- **modal**: functions concerning the common modal dialog logic
- **home**: landing page, static ("wiki") pages, other content pages, global announcements
- **course**: course page, course content from the learners' perspective
- **teacher**: everything in the "Course Administration" menu
- **admin**: everything in the global "Administration" menu
- **account**: login/logout, account merge, registration, SSO, ...
- **user**: profile, settings, dashboard, certificates

!!! info
    While transitioning to a component-based frontend, we noticed a tendency to add JavaScript belonging to globally scoped components to the `main.js` bundle. This trend inflates the module originally intended for small, shared functions and initializers. We may need to rethink our strategy there.

## How to add new code to a bundle

1. Determine which module your new component or script belongs to
2. Add your code in the module folder located in `app/assets`

    !!! info
        `app/assets/javascripts` is part of the sprockets pipeline.
        Do not add new scripts here.

3. Register the new script in the module-specific entries file
4. Compile assets with `yarn build`
5. Check the Webpack output for the bundled files

If not already the case, don't forget to import the bundle in the view with the [`javascript_include_tag`](https://apidock.com/rails/ActionView/Helpers/AssetTagHelper/javascript_include_tag).

## Adding a new node module

We are using [yarn](https://yarnpkg.com/) to manage our frontend dependencies.
Use `yarn add` to integrate new node modules (do not use `npm install`).
