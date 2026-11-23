# AGENTS.md

This file provides guidance to Coding Agents when working with code in this repository.

## What this is

Xikolo — the Rails code base behind the openHPI MOOC platform.
Ruby 4.0 / Rails 8.1. JavaScript is managed with **bun** (not yarn/npm), version pinned in `.bun-version`.

## Setup & running

- `bin/setup` — install deps (bundle + bun), configure local S3, create/prepare dev and test DBs. `bin/setup --reset` wipes and recreates everything (requires a running Minio/S3).
- `bin/dev` — start two Rails servers, the Solid Queue job processor, and asset watchers.

## Architecture

### Direction for new and changed code

The goal is a conventional Rails application. The engines are a transitional way to bring the former services into the monolith; their resources should gradually move into the main app. Prefer standard Rails models, controllers, jobs, and mailers, with plain Ruby objects (POROs) for business logic where needed, rather than extending the custom framework layers.

Restify, Acfs, `app/forms/`, `app/inputs/`, `app/handlers/`, and Draper decorators in `app/presenters/` are legacy. The decorators mainly adapt JSON resources from the internal APIs; they are not a required presentation layer for the target Rails app. Trace them to understand existing behavior, but do not use their presence as a recommendation for new code. Avoid introducing new internal HTTP calls or extending these legacy abstractions. Use existing engine models directly while they remain in the engines, and standard Rails views, helpers, and ViewComponents for presentation as appropriate. Keep migrations scoped to the requested work; touching legacy code does not require moving an entire resource or subsystem.

### Current structure (including legacy code)

This started as separate microservices and is now a **single Rails app that plays both roles**:

- **Internal services** live as Rails engines in `engines/` (`account_service`, `course_service`, `news_service`, `notification_service`, `pinboard_service`, `quiz_service`). Each is mounted under `/<name>_service` in `config/routes.rb` and exposes a JSON API (controllers under an `api` namespace, e.g. `engines/account_service/app/controllers/account_service/api/`). Engines hold the persisted models and the operations that mutate them.
- **The frontend app** (`app/`) renders the UI and talks to those services **over HTTP**, using the client gems in `clients/` (`xikolo-account`, `xikolo-course`, `xikolo-pinboard`, `xikolo-quiz`, `xikolo-submission`).
- In development, `bin/dev` runs the frontend on port 3000 and the mounted services on port 3333. The frontend connects to the services using `XIKOLO_SERVICE_*` environment variables. Internal service calls use the `XIKOLO_WEB_API` bearer token for authentication. See `constraints/service_authorization_constraint.rb`.
- Service databases have since been consolidated into one, so **foreign keys are now allowed and encouraged** (historically they weren't).

HTTP clients use two libraries: **Restify** and **Acfs** (legacy). The long-term goal is to remove both.

Local path gems live in `gems/` (`xikolo-common`, `xikolo-config`, `xikolo-s3`, `xui-form`).

### Existing frontend app layering (`app/`)

Existing code often follows `controllers/` → `operations/` (business actions, subclass `ApplicationOperation`) and legacy `forms/` (often via the `xui-form` gem). This describes the code to navigate, not a required structure for new implementations. Presentation uses legacy `presenters/` (Draper decorators adapting internal API JSON), `components/` (ViewComponent), and `views/`. Templates are a mix of **Slim** and **ERB (Herb)**, but **Slim is deprecated — write new views in ERB** and migrate Slim to ERB when touching it. Legacy `handlers/` and `inputs/` coexist with standard Rails `jobs/` and `mailers/`.

## Testing

RSpec is the test runner. Specs mirror the layers: `spec/components`, `spec/presenters`, `spec/lib` (unit), `spec/models` and `spec/requests` (integration/request), and `spec/system` (browser). Engine specs live alongside app specs: `spec/account_service/`, `spec/course_service/`, etc.

Prefer request, component, and unit specs. Add or extend a system test only when it covers a meaningful risk that requires a real browser, such as behavior that depends on JavaScript or browser navigation. Explain that risk when reporting the change.

- Check existing coverage first. Do not add system tests merely because production code changed.
- Keep each system scenario focused on one user goal. Test independent behaviors and edge-case combinations at lower layers.
- Create only the data needed for that goal. Prefer direct setup through factories or helpers; use the UI for setup only when those steps are themselves under test.
- Use Capybara's waiting assertions and accessible roles, labels, or explicit test selectors; avoid DOM structure and styling classes. Do not add arbitrary sleeps, increase timeouts, or add retries to make a test pass.
- Avoid extending a scenario if doing so adds unrelated setup, navigation, or interactions.
- If reliable browser coverage requires substantial scaffolding, reconsider the test layer before proceeding.

## Lint, format, build

Ruby:

```sh
bundle exec rubocop --parallel        # add -a / -A to autocorrect
```

JS / CSS / templates / docs (all via bun):

```sh
bun run tsc:check       # TypeScript
bun run lint:js         # eslint (app/javascript)
bun run lint:css        # stylelint
bun run lint:herb       # ERB templates
bun run lint:md         # markdown
bun run format          # prettier --write .
```

Assets:

```sh
bun run build           # JS bundle (bun.config.js)
bun run build:css       # tailwind + sass
```

## Conventions

- Keep routing/controllers RESTful. Prefer member/collection routes over new controllers or non-REST actions; extra routes only for alternate presentations of the same resource (export/filter/format).
- Frontend: write new JS as **TypeScript** (follow patterns in `app/javascript/`); migrate existing JS over time.
- Styling: use **Tailwind** utilities over custom CSS. The SCSS codebase is **legacy** — don't add to it.
- UI uses **daisyUI** components — reference them with the `x-` prefix in views.
- Forms: **simple_form is deprecated.** Use the built-in [Action View Form Helpers](https://guides.rubyonrails.org/form_helpers.html) instead (`form_with`, `text_field`, `check_box`, etc.). Migrate existing simple_form usage when touching those views.
- Internationalization: app supports `de` and `en`. `bundle exec rake i18n:missing_keys` lists translation keys absent from some locale; JS translations are exported via `rake assets:i18n:export`.
