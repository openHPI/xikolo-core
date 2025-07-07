# System alerts

System alerts are a navigation component that informs users about important system messages and updates, thus enabling quick and effective communication to *all* users.
For example, alerts can be used to communicate planned downtimes or provide information about current operational issues, such as performance degradation.

Alerts are displayed as a prominent, blinking megaphone and can contain links as well as other Markdown content.
Users must actively dismiss the popover to hide it.

## Functionality

### Displaying alerts

- The component displays system notifications in the form of a popover.
- When new alerts are available, the popover opens to draw users' attention.
- Once users have read the alerts or closed the popover, the messages remain accessible via a dropdown.

### Caching

- Alerts are retrieved from the database and cached per language for five minutes.
- The visibility of new alerts is managed using a cookie (`seen_alerts`).
- Read alerts are stored via cookies to prevent users from seeing the same notification repeatedly.

## Configuration and localization

Alerts can be created via the Rails console of `xi-web`:
[Using Nomads web UI, connect to `xi-web`](https://nomad.adm.production.openhpi.xi.xopic.de/ui/exec/xikolo/web-app/server) (don't forget to press Enter here) and run

```shell title="xi-web:/app$"
rails c
```

```ruby
Alert.create!(
  publish_at: 1.hour.ago,
  publish_until: 2.hours.from_now,
  translations: {
    'en' => {
      'title' => 'Planned downtime',
      'text' => 'The _platform_ will be **unavailable for the next hour**. For further information on downtimes, [refer to this page](https://en.wikipedia.org/wiki/Downtime).',
    },
  }
)
```

The `text` in the `translations` supports Markdown, allowing formatting and links.
