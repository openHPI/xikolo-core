<!-- markdownlint-disable-file MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

---

### New

### Changes

### Fixes

### Breaks

## 2.18.0 - (2023-06-21)

### Changes

- De-privatized constants to use them with verified stubs in web

## 2.17.0 - 2021-03-04

### Added

- Compatibility with Rails 6 and 6.1

## 2.16.1 - 2020-12-21

### Fixed

- Fixed error raising on missing service stub

## 2.15.0 - 2020-03-25

### Added

- Updated telegraf to `0.5.0`.

## 2.14.0 - 2020-01-20

### Added

- HTTP stubs with `Stub.request` can now match based on URI templates.

## 2.13.0 - 2019-11-04

### Added

- A new `Xikolo.metrics` object allows consistent collection of custom metrics / time series. Explained in new README.

## 2.12.0 - 2019-07-31

### Changed

- `ExternalLink` now supports `Addressable::URI` (for compatibility with `Xikolo.config.base_url`).
- `RSpec#setup_session` now takes a `context_id` parameter

## 2.11.0 - 2019-01-15

### Added

- Expose `#interrupts` array on `CurrentUser` classes - this returns an array of interrupt reasons, straight from xi-account

### Deprecated

- `CurrentUser#interrupt_session?` and its aliases should no longer be used, in favor of the new `#interrupts` method.

## 2.10.1 - 2018-11-26

### Added

- `Stub.enable` helper method to enable a services for current test (without stubbing the root URL)

### Changed

- Raise understandable error message if `Stub.request` is called with an unknown service name.

## 2.10.0 - 2018-11-15

### Changed

- We now disable all services without stubs for each RSpec test case. An explicit `Stub.service` is required to reconfigure this service.

## 2.9.0 - 2018-11-09

### Added

- New method `interrupt_session?` on `CurrentUser` objects that returns `true` when the session should be interrupted as soon as possible, e.g. when a new consent is required from the user

## 2.8.0 - 2018-11-05

### Added

- New method `Xikolo.api?` for determining whether a service has been configured

### Changed

- `Xikolo.api(:some_service)` now returns a dedicated `Xikolo::Common::API::ServiceNotConfigured` exception when a service is unknown.

## 2.7.1 - 2018-09-26

### Fixed

- Rake task `xikolo:migrate_permissions` failed when config/permissions.yml does not exist

## 2.7.0 - 2018-08-10

### Changed

- Global support for Msgpack in `Accept` header (with JSON fallback)

### Removed

- Support for older versions of Restify (&lt; 1.6)

## 2.5.0 - 2018-03-06

### Added

- Retry connecting to the account service on permission migration

## 2.4.1 - 2017-11-30

### Fixed

- Even when called with a user ID, `setup_session` stubbed a response that would be interpreted as belonging to an anonymous user.

## 2.4.0 - 2017-11-29

### Added

- Support `factory_bot` as well as `factory_girl` (which can be considered deprecated)

## 2.3.1 - 2017-10-10

### Fixed

- `rake xikolo:migrate_permissions`: Do not crash when some of the sections in a permissions.yml file are not defined
- `rake xikolo:migrate_permissions`: Fail with a proper exit code when the account service is not running

## 2.3.0 - 2017-09-27

### Added

- The paginator's `each_item` method (and `Xikolo.paginate` when it is given a block) now passes the current page to the provided block as well

## 2.2.1 - 2017-09-20

### Changed

- `rake xikolo:migrate_permissions`: Warn when the account service is not running

## 2.2.0 - 2017-09-18

### Added

- User preferences can now be retrieved via `Xikolo::Common::Auth::CurrentUser#preferences`

## 2.1.0 - 2017-09-14

### Added

- Pagination for Restify requests via `Xikolo.paginate`

### Changed

- The `Xikolo::Common::Auth::Middleware` middleware does not try to rescue Restify exceptions anymore.
  Because it only registers a promise, the exception would be raised when calling `value!` on that promise, which is the responsibility of this library's consumers.

## 2.0.0 - 2017-06-22

### Added

- The `Xikolo::Common::Auth::CurrentUser` class now provides all methods required in e.g. xikolo-web.

### Changed

- The `Xikolo::Common::Auth::Middleware` middleware now supports fetching the user with permissions for a specific context.
  The context needs to be set in the request environment under `xikolo_context` (either as a string or a promise resolving to a string) _before_ the middleware is executed.

### Removed

- The (previously deprecated) `stub_restify` helper method for RSpec tests is now gone.
  Use `Stub.request` and `Stub.service` instead.
- The (previously deprecated) `Xikolo::Common::AuthMiddleware` and `Xikolo::Common::CurrentUser` classes are now gone.
  Use `Xikolo::Common::Auth::Middleware` and `Xikolo::Common::Auth::CurrentUser` instead.
- The subclasses of `Xikolo::Common::Auth::CurrentUser` are now marked as private.
  User instances should only be created through `Xikolo::Common::Auth::CurrentUser.from_session`.
