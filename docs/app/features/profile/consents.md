# Consents

To use collected user data for research purposes or reach out to the user, e.g. for
marketing purposes, users are required to give / refuse their consent for these actions.

In the data model, ``consents`` can be understood as the permission from a user to a ``treatment``,
which represents the type of consent.

Consenting to a treatment can either be ``required`` or ``optional``.
When a consent is required, no further action is possible for the user on the platform until
the consent has been given. Optional consents are presented to the user but can be
dismissed and will not be shown again.

All consents can be managed on the user's profile page later on.

## External consents

Treatments can also be managed by a third party consent manager, meaning that the consent is handled externally.
For that, an external link is displayed, directing the user to the external page to manage the consent.

In the data model, external ``treatment``s need to be configured with a consent manager.

```ruby
{type: 'external_tool', consent_url: 'https://www.example.com/consents'}
```

For each ``type``, a custom integration needs to be developed, allowing to fetch a
user's consent status and update the consent information in the external management system.
