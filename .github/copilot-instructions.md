<!--
Purpose: Short, actionable guidance for AI coding agents working in this repository.
Keep it concise; reference files and commands developers actually use.
-->

# Repo-specific Copilot instructions (concise)

- Purpose: help an AI agent be productive quickly in this Rails + engines monorepo.

- Quick start (development):
  - Use `bin/dev` to start all services and asset watchers in one command

- Architecture summary:
  - Monorepo combining a Rails web app (`app/`) with multiple internal engines/services in `engines/` and service folders under `services/`.

- Project-specific conventions / patterns to follow:
  - Feature-style modular components under `app/components` and UI parts under `app/views` — follow existing structure for new components.
  - Use `erb` templates for views; `slim` is deprecated. Refactor existing views to `erb` if possible.
  - Use TypeScript for new frontend code; existing JS can be migrated over time. Follow patterns in `app/javascript/` for new code.
  - Use the `x-` prefix for daisyUI components in views.

- Key files and where to look for examples:
  - Routes and constraints: `config/routes.rb` for request-level routing rules.
  - Asset toolchain: `package.json`, `bun.config.js`, `build_sass`, `tailwind` scripts.

- Tests & verification:
  - Unit/integration: RSpec is present under `spec/`. Run `bin/rspec` or `bundle exec rspec` for test runs.
  - Integration/system tests: check `integration/` directory and `features/` for higher-level tests.

- Common developer workflows (explicit commands):
  - Install deps: `bundle install` and `bun install` (or consult root README).
  - DB tasks: use `bin/rake db:setup`, `bin/rake db:migrate`.
  - Linting: `rubocop` and `eslint` are configured; prefer the repo scripts.

- Code-editing guidance for AI agents:
  - Make minimal, focused changes; update corresponding tests.

If anything above is unclear or you want more depth about a specific subsystem (assets, messaging, or a particular service/engine), tell me which and I'll expand the instructions or add examples.
