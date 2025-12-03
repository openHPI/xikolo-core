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
