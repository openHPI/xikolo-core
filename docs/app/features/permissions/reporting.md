# Reporting permission

The reporting role must be assigned to users manually. There is no UI for it as this concerns access to sensitive data and is also a policy issue for some stakeholders.
It can be granted or revoked on the production systems via the Rails console of `xi-account`:

[Using Nomads web UI, connect to `xi-account`](https://nomad.adm.production.openhpi.xi.xopic.de/ui/exec/xikolo/account-api/server) (don't forget to press Enter here)

```shell title="xi-account:/app$"
rails c
```

## Grant the reporting role

1. List all emails of the users who should get the reporting role.

    ```ruby
    emails = %w[email@example.com]
    ```

2. Grant the reporting role for each user. Check the output for errors.

    ```ruby
    r = Role.find_by(name: 'lanalytics.report.admin')
    c = Context.root

    emails.map do |email|
      user = User.query(email).first

      puts "No user found for #{email}" unless user
      next unless user

      Grant.create!(principal: user, role: r, context: c)
    end
    ```

## Revoke the reporting role

1. List all emails of the users who should have their reporting role revoked.

    ```ruby
    emails = %w[email@example.com]
    ```

2. Remove the reporting role for each user. Check the output for errors.

    ```ruby
    r = Role.find_by(name: 'lanalytics.report.admin')

    emails.map do |email|
    user = User.query(email).first

    puts "No user found for #{email}" unless user
    next unless user

    Grant.find_by(principal: user, role: r)&.destroy!
    end
    ```

## List all users with the reporting role

```ruby
r = Role.find_by name: 'lanalytics.report.admin'
user_ids = Grant.where(role: r, principal_type: 'User').pluck(:principal_id)

pp User.where(id: user_ids).map(&:email)
```
