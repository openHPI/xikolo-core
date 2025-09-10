# Using Staging and Testing Environments

Before deploying changes to production, it is sometimes advisable to thoroughly test them in non-production environments first.
This practice helps identify potential issues, validates functionality, and minimizes the risk of introducing bugs to the live system.

We have two dedicated non-production platforms:

- <https://staging.openhpi.de>
- <https://testing.openhpi.de>

## Platform Reservation Process

For an organized development workflow to prevent conflicts,
we implement a reservation system for our non-production platforms.
This ensures that developers don't accidentally overwrite each other's code changes or interfere with ongoing testing activities.

### How to Reserve a Platform

When you need to use either the staging or testing environment for your development work, please follow these steps:

1. Navigate to the `#rollout` channel in our Slack
2. Announce that you would like to deploy on testing or staging
3. Update the channel description to include your name and optionally the ticket reference you're working on

Use the following format to indicate your reservation:

```text
hpi-staging: Developer name (Ticket ref.) | hpi-testing: -
```

In this example, `hpi-staging` is reserved by a specific developer working on a particular ticket, while `hpi-testing` remains available for others to use.

!!! note

    Remember to update the channel description when you're finished with your testing.
