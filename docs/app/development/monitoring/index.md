# Monitoring

## Sentry

Sentry is a tool used for monitoring, prioritizing, and debugging errors. The [dashboard](https://openhpi.sentry.io/issues/) provides real-time visibility into platform errors and it enables developers to quickly identify and resolve issues that impact application performance and user experience.

- **Error Monitoring**: Errors on our platforms are reported to Sentry, with detailed information about each error, including the stack trace, request information, and metadata. One can know in which brand the error was caused, which application (e.g web, courses, pinboard) as well as information on the client side (operating system).

An example of how our app reports errors to Sentry:

```ruby
rescue Restify::ClientError => e
  ::Sentry.capture_exception(e)
```

- **Prioritization**: It automatically groups similar errors together, so errors that are occurring most frequently can be prioritized accordingly.

- **Debugging**: Sentry provides detailed information about each error, making it easier to identify the root cause and fix the defect.

### Ignoring errors in Sentry

There are several reasons to set errors on Sentry to be ignored.
One common reason is to avoid being alerted about errors that are not actionable or those that cannot be fixed. This helps us avoid being overwhelmed by alerts that are not relevant.

To see the list of all errors that are currently ignored, one can go to the "Ignored" tab:

![Screenshot: ignored errors in Sentry](ignored_issues.png)

There are essentially two ways in which Sentry is set to ignore errors. One is via config.

This is a sample configuration for excluding certain exceptions:

```ruby title="config/initializers/sentry.rb"
config.excluded_exceptions += %w[
  Acfs::BadGateway
  Acfs::GatewayTimeout
  Acfs::ServiceUnavailable
  Status::NotFound
  Restify::BadGateway
  Restify::GatewayTimeout
  Restify::ServiceUnavailable
  ApplicationJob::ExpectedRetry
]
```

In Sentry, one can ignore errors by creating an ignore rule. Ignore rules allow specifying certain conditions that, when met, will cause Sentry to ignore specific errors.

To create an ignore rule, go to the "Issues" page in Sentry and click on the "Ignore" button next to the error to be ignored. From there, the conditions can be specified for which the error should be ignored. For example, one can ignore errors that contain certain keywords or that come from specific users or IP addresses.
