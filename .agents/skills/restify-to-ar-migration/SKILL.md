---
name: restify-to-ar-migration
description: Refactor one Xikolo Rails controller and its related collaborators and specs from internal Restify HTTP resources to namespaced ActiveRecord models. Use when replacing `Xikolo.api(...).rel(...)` calls, Restify resource hash access, promises, embedded resources, or `Stub.request` service stubs with direct engine model queries, associations, factories, and behavior-focused tests while preserving controller behavior.
---

# Migrate Restify to ActiveRecord

Migrate one controller-sized slice at a time. Replace only internal service calls whose persisted models live in this monolith. Preserve behavior rather than mechanically translating the old endpoint syntax.

## Establish the migration boundary

1. Read the complete target controller, its routes, superclass, concerns, before-actions, and existing request or controller specs.
2. Trace every Restify-loaded resource through operations, forms, presenters, components, helpers, views, jobs, and model methods used by that controller. Search by controller name, instance-variable names, presenter constructors, and resource attributes.
3. Inspect the corresponding engine model, associations, scopes, operation, API controller, serializer, and factory. Treat endpoint filtering, authorization, ordering, defaults, embeddings, computed fields, and mutations as part of the current contract.
4. Check the working tree and preserve unrelated changes. Run the narrowest relevant specs before editing to establish a baseline. If the migrated behavior has no useful coverage, add the narrowest characterization request spec before changing production code.
5. List which HTTP calls will become ActiveRecord access. Leave unrelated Restify or Acfs calls intact, including calls made by authentication or collaborators outside the chosen slice.

Use `rg` to find the full slice. Typical searches include:

```sh
rg -n "Xikolo\.api|\.rel\(|\.value!|Stub\.request|Stub\.json" app spec
rg -n "ControllerName|PresenterName|@resource|resource\[['\"]" app spec
rg -n "factory :'service_name/model_name'|class ModelName" engines spec/factories
```

## Derive the ActiveRecord equivalent

Do not infer behavior from the Restify relation name alone. Confirm the model and query against the engine implementation.

### Reads

Translate a singular ID lookup to the namespaced model:

```ruby
# Before
user = account_api.rel(:user).get({id: user_id}).value!

# After
user = AccountService::User.find(user_id)
```

Use `find` when the endpoint raised for a missing record. Use `find_by!` for another unique key and `find_by` only when `nil` was valid. Preserve UUID normalization when the endpoint performed it.

Translate collection endpoints to the same scopes, filters, order, and limits implemented by the endpoint:

```ruby
# Before
courses = course_api.rel(:courses).get({channel_id:, published: true}).value!

# After — only after confirming these scopes match endpoint semantics
courses = CourseService::Course.where(channel_id:).published.order(:position)
```

Prefer model associations over manual foreign-key queries when the association expresses the same contract:

```ruby
# Before
emails = user.rel(:emails).get.value!

# After
emails = user.emails
```

Preserve endpoint ordering explicitly if the association has no matching default order. Use `includes` or `preload` when rendered collections would otherwise introduce N+1 queries. Do not reproduce API pagination metadata unless the caller actually consumes it.

### Embedded and computed fields

Restify resources can contain serialized fields that are not database columns. For each field, identify whether its ActiveRecord equivalent is:

- a column reader;
- an association;
- a model or presenter method;
- a scope-derived value;
- formatted output such as ISO 8601 timestamps or string IDs;
- or endpoint-only behavior that should remain behind an operation.

Do not translate an embedded hash mechanically. For example, `resource['translations']` may require an association plus locale selection, not `resource.translations` at every call site.

### Writes

Use the engine's existing operation when the API endpoint delegates to one or performs side effects. Otherwise use the namespaced model with the same validation and failure semantics:

```ruby
record = Service::Record.create!(attributes)
record.update!(attributes)
record.destroy!
```

Inspect endpoint parameter transformation before passing a form resource directly into ActiveRecord. Remove API-only keys, add required foreign keys, and preserve transactions, callbacks, enqueueing, audit events, and dependent changes.

Replace obsolete `Restify::*` rescue clauses with the exception or validation flow raised by the new path. Keep the controller's response status, flash, redirect, and form errors unchanged. Do not silently switch between bang and non-bang persistence methods.

### Promises and relation chaining

Remove `.value!` and HTTP promise plumbing after replacing the request. Write synchronous control flow directly rather than retaining `.then` chains that obscure the new object type.

```ruby
# Before
account_api.rel(:user).get({id: user_id}).then { |user| user['email'] }.value!

# After
AccountService::User.find(user_id).email
```

Delete a now-unused private API client method only after confirming no call remains in the file.

## Convert resource access through the whole slice

Restify resources are hash-like; ActiveRecord records expose methods. Update the controller and every related collaborator receiving the changed object:

```ruby
user['email']       # before
user.email          # after

course['id']        # before
course.id           # after

record['starts_at'] # before
record.starts_at    # after
```

Search for string and symbol subscripts, `fetch`, `dig`, `merge`, `to_h`, embedded collections, and URL relations on each migrated variable. Also update presenter constructors and methods whose implicit input contract changes from resource to model.

Do not change parsed JSON response assertions such as `json['id']`; those values are still hashes. Do not convert configuration hashes or unrelated resources merely because they use bracket access.

If a form or legacy presenter still deliberately accepts a resource hash, create that boundary explicitly with an existing serializer or `to_resource` method. Do not scatter `as_json` calls to imitate Restify; prefer teaching the collaborator to accept the model when that is the intended migration.

## Replace migrated service stubs with records

Replace only stubs for HTTP calls removed from production code. Use an existing namespaced factory and make its persisted attributes match the IDs and state used by the request:

```ruby
# Before
let(:course) { build(:'course:course') }

before do
  Stub.request(:course, :get, "/courses/#{course['id']}")
    .to_return Stub.json(course)
end

# After
let(:course) { create(:'course_service/course') }
```

Use the actual factory name found under `spec/factories`; do not invent an unnamespaced factory. Prefer `let` when the request references the record and `let!` or an explicit reference in `before` when the record must exist before the request but is otherwise not referenced.

When request params or remaining stubs depend on the record, change their access too:

```ruby
let(:params) { {course_id: course.id} }
```

Keep stubs for service calls that production code still performs. A spec can legitimately contain both factories for migrated access and stubs for unmigrated calls.

Replace transport assertions with observable behavior or database effects:

- rendered content and response status for reads;
- created, changed, or destroyed records for writes;
- ordering, visibility, locale, and permission behavior previously encoded in query parameters;
- absence behavior and error responses;
- side effects such as jobs or notifications.

Do not merely delete an unmet stub expectation. Preserve the behavior it was proving with a record setup and assertion. Avoid testing ActiveRecord itself; test the controller contract.

Update factory traits only when existing factories cannot express a state repeatedly needed by the migrated specs. Keep factory changes general and consistent with existing namespaced patterns.

## Verify the complete slice

1. Run the affected specs after each logical change. Diagnose unexpected zero-call stub failures: remove the stub only if its production call was intentionally migrated.
2. Run RuboCop on every changed Ruby file and the relevant template linter if views changed.
3. Run `git diff --check`.
4. Search the controller and related files for remaining migrated-client calls and hash-style access.
5. Review the diff against the old API controller and serializer to confirm filters, ordering, permissions, not-found handling, validation errors, and side effects remain equivalent.
6. Report changed files, verification commands and results, retained Restify calls, and any behavior that could not be exercised.

Do not claim the controller is migrated while related presenters or specs still assume Restify resources. Do not expand the task into an engine-wide migration unless the user asks for it.
