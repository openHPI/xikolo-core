# Project guidelines

The Xikolo project has evolved with multiple coding styles. These guidelines clarify inconsistencies.

## Routing

In this project, we use **Rails RESTful routing** as the foundation for defining application routes.

### Standard Resources

- Use the `resources` method to declare routes for a nameable resource.
- This automatically generates the standard RESTful actions (index, show, new, create, edit, update, destroy).

```ruby
resources :projects

```

### Extra Routes

- Keep extra routes to a minimum.
- Only add them if they represent different presentations of the same resource (e.g., exporting, filtering, or returning data in another format).
- Prefer member routes (acting on a single resource) and collection routes (acting on the full set) over introducing entirely new controllers.

```ruby
resources :projects do
  member do
    get :preview   # /projects/:id/preview
  end

  collection do
    get :archived  # /projects/archived
  end
end

```

!!! note

    Keep controllers RESTful. If a route does not naturally fit a REST action, reconsider whether it belongs in the current controller.

## Foreign keys

Historically, Xikolo used a microservice architecture where each service had its own database, which made it impossible to use foreign keys. Since the databases have been consolidated, this limitation no longer applies, and using foreign keys is now recommended.

> While it's not required, you might want to add foreign key constraints to guarantee referential integrity.

[Rails guides](https://guides.rubyonrails.org/active_record_migrations.html#foreign-keys)

## Restify over Acfs

The goal is to replace [Acfs](https://github.com/jgraichen/acfs) resources with [Restify](https://github.com/jgraichen/restify). When adding a feature to a service that still uses Acfs, use Restify to avoid increasing the migration workload.

!!! note

    The long-term goal is to fold in the remaining services. Eventually, neither Acfs nor Restify will be required.
