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

## Forms

**simple_form is deprecated.** Use the built-in [Action View Form Helpers](https://guides.rubyonrails.org/form_helpers.html) instead.

- Use `form_with` for forms, `text_field`, `check_box`, `select`, etc. for inputs
- Migrate existing simple_form usage when touching those views

## Foreign keys

Historically, Xikolo used a microservice architecture where each service had its own database, which made it impossible to use foreign keys. Since the databases have been consolidated, this limitation no longer applies, and using foreign keys is now recommended.

> While it's not required, you might want to add foreign key constraints to guarantee referential integrity.

[Rails guides](https://guides.rubyonrails.org/active_record_migrations.html#foreign-keys)

## Restify and Acfs

Restify and Acfs are deprecated. Don’t introduce new calls. Use the corresponding namespaced ActiveRecord models, associations, scopes, and operations. For AI guided restify refactorings, use the `restify-to-ar-migration` skill.
