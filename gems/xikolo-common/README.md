# Xikolo Common Utilities

The gem `xikolo-common` helps doing things we do in every Ruby-based service:

- It installs libraries we use everywhere (such as Restify for HTTP communication between services).
- It configures libraries we often use.
- Most importantly, it provides several helpers under the `Xikolo` namespace. These include a method for paginating across Restify requests, a class for authenticating with the account service, and many more...

## Usage

### Collecting app-specific metrics with Telegraf

Using the `Xikolo.metrics` object, you can send data to the pre-configured [Telegraf data collector](https://github.com/influxdata/telegraf) that is available on production machines.
This is useful when you want to evaluate custom application or engineering metrics across time.
We have used this successfully to inspect the expected effects of large refactorings or the hit/miss ratio in a custom caching layer.

Data tracked via `Xikolo.metrics` will be available for inspection in our central Grafana instance.

```ruby
Xikolo.metrics.write(
  'my-series',
  tags: {
    controller: params[:controller],
    action: params[:action],
  },
  values: {
    path: request.path,
  }
)
```

Every time you want to add another event to our time-series database, you can call `Xikolo.metrics.write`.
This method expects three parameters:

- a name for the metric / series,
- a hash of `tags` which can be used to filter and group the data, and
- another hash of `values` which can contain any meta data, but more importantly can be used for display, usually using some form of aggregation (e.g. counting).

Tags are automatically used for indices and must have a limited cardinality.
For example, do not add the User UUID as a tag, as this would create a new index for each single value (as all UUIDs are unique).
Usual attributes with limited cardinality are e.g. controller or action names.

The type of values (int, float, string) cannot be changed after metrics have been written.
Metrics with invalid types will be silently dropped.
