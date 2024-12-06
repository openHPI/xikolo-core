# xi-notification - Sending emails for all of Xikolo

## Styling HTML emails

Making HTML emails look great in most / all email clients is a challenge.
Especially Microsoft Outlook is a hassle.

Fundamentals:

- Inline styles on elements using `style` attributes (done by [premailer](https://github.com/premailer/premailer/))
- Alignment with tables (encapsulated by [inky](https://github.com/foundation/inky-rb) template helpers)
- Avoid custom styles, especially for responsiveness, use helpers from inky / [foundation](https://get.foundation/emails/docs/) instead

Other things to keep in mind:

- Use full six-digit color codes (e.g. `#666666`), avoid shorthands like `#666`
- [More tips and caveats](https://get.foundation/emails/docs/tips-tricks.html#css)

## How to send notifications

Notifications are sent in services using Msgr and received in the notification service.

### Send

```ruby
data = {
  timestamp: DateTime.now,
  link_to: {
    resource_key: 'Xikolo::Service::Resource',
    resource_id:  '00000001-1234-4444-9999-000000000001'
  },
  # ...
}
Msgr.publish(data, to: 'xikolo.service.resource.action')
```

The `link_to` hash is used to create a link in the frontend and emails.

For some events where we do not send out mails the link might be generated in the Web-API.

### Receive

Add route in `xikolo_services_notification/config/msgr.rb`:
`route 'xikolo.service.resource.action', to: 'consumer#method'`

If not existing, create a Consumer and a ConsumerHelper with the specified method. Create a notification there, as done in the existing consumers. Make sure to forward the timestamp to the Notification.

Add a mail template for the `topic_exchange` in `app/views/{de|en}`.

### Display

Add a description for the `topic_exchange` to be displayed in the preferences in the frontend's locales under
`preferences.show.xikolo.service.resource.action`.
