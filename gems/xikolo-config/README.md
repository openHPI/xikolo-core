# Xikolo Configuration

The gem `xikolo-config` is a simple key-value store for site-specific configuration.

Things like email addresses should not be hard coded in our application code directly. They are only valid for specific platform instances. This gem provides an easy way to read values from YAML config files, which can be overwritten in production environments to configure the application(s).

## Primary Configuration Options

### Brand

The internal "brand" identifier which determines the visual theme of the application (for stylesheets / images / email templates etc.). It usually does not change between staging and production environments for the same platform. Its default value is `xikolo`.

It SHOULD be accessed via string inquirer on the Xikolo module:

```ruby
Xikolo.brand.xikolo?
# => true

Xikolo.brand.outdated?
# => false
```

### Base URL

The base URL where the frontend is reachable. This value SHOULD be used to create absolute URLs where no HTTP request context is available to determine the correct host, e.g. in services, mailers or background workers.

It includes the expected protocol, domain and base path. It SHOULD be accessed using the `Xikolo#base_url` method. Furthermore, it returns a `::Addressable::URI` object supporting `#join`:

```ruby
Xikolo.base_url.to_s
# => "https://xikolo.de/"

Xikolo.base_url.join("files/#{file_id}")
# => "https://xikolo.de/files"
```

_Note_: You SHOULD NOT join with an absolute path (e.g. `/files/...`) as that would strip a possible relative base path from the base URL.

## Other Configuration Options

- **Xikolo.config.mailsender** (``): Overwrite the mail sender, defaults to `no-reply@maildomain` if nil or empty
- **Xikolo.config.site_name** (`Xikolo`): Title / display name for this installation (e.g. `Company`, `Company Staging`). Designed to be displayed to the user.
- **Xikolo.config.locales:**
  - **Xikolo.config.locales['available']** (`['de', 'en', 'es', 'fr', 'ru', 'cn']`): The list of locales that can be selected / used on the platform
  - **Xikolo.config.locales['default']** (`en`): The locale that should be used for anonymous users
- **Xikolo.config.ui_primary_color** (`#FFC04A`): Primary UI color

## Deprecated options

Currently, none.

## Other options

Other configuration values can be accessed by `Xikolo.config`

```ruby
> Xikolo.config.unknown_option
=> nil
> Xikolo.config.statistics_email_recipients
=> ["statistics@example.com"]
```

## Add a new value

> **NOTE:** Do not add new config values in this gem, unless explicitly decided by the team!

1. Add a short documentation about your option into this README.
2. If you have a default value, add it to `lib/xikolo/config.yml` and a test to `spec/lib/xikolo/config_spec.rb`.
3. Release a new version of this gem
4. Use the new gem version
5. Talk to someone to configure the production systems with the specific values.

## Config file locations

When included in a Rails project, Xikolo config reads the following files, in the order listed here.
The top-level keys are merged, the last file containing a key wins:

1. Gem
2. `app/xikolo.yml`
3. `/etc/xikolo.yml`
4. `~/.xikolo.yml`
5. `config/xikolo.yml`
6. Gem environment specific defaults
7. `/etc/xikolo.#{Rails.env}.yml`
8. `~/.xikolo.#{Rails.env}.yml`
9. `config/xikolo.#{Rails.env}.yml`

Machine-specific configuration (everything in `/etc` or the user's home directory) is ignored in test environments.

## Specifying instance specific values

`xikolo-config` reads the file `/etc/xikolo.yml` if it exists.
In this file, all instance-specific values should be setup.
For our production platforms, this file is managed by Salt and the values are generated hierarchically per platform / environment.

## Integration

Settings to apply in all services and all scenarios, can be put into `features/support/lib/xikolo.yml`.

To enable boolean options for specific features or scenarios, use `@with:${name}` tag. To disable an option for specific features or scenarios use `@without:${name}`.
