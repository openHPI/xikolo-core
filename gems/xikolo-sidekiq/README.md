# Xikolo Sidekiq Configuration

This gem sets up [Sidekiq](https://github.com/mperham/sidekiq) in a Rails project.
It takes care of all necessary configuration, sets up Sidekiq to be used with ActiveJob (if desired), and contains useful Rake tasks for dealing with Sidekiq queues.

The gem lets you configure the Sidekiq Redis connection via another configuration file, `config/sidekiq_redis.yml`.
This file can contain various Redis configuration keys, with different settings for each Rails environment:

```yaml
development:
  db: XX01

test:
  db: XX02

integration:
  db: XX03

production:
  db: XX04
```

Replace `XX` with the range assigned to your service (like for the port to use).

## Cron jobs

Additionally, if the `sidekiq-cron` gem is also installed, this gem will load and parse a `config/cron.yml` file.
This file can be used to configure which Sidekiq worker should be run periodically at which interval, per environment.

### Example

```yaml
production:
  stat_mails:
    cron: '0 2 * * *'
    class: StatMailWorker
  pinboard_digest:
    cron: '0 4 * * *'
    class: PinboardDigestWorker
```

This will set up two cronjobs (both of which will only run in the production environment):

- the `StatMailWorker` will run every day at 2 AM, and
- the `PinboardDigestWorker` will be executed once a day at 4 AM.
