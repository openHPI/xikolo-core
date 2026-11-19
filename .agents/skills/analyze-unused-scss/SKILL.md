---
name: analyze-unused-scss
description: Analyze Rails SCSS import graphs and selectors to find unused project styles by cross-referencing compiled entrypoints with ERB, Slim, ViewComponent, Ruby helper/presenter, and JavaScript class usage. Use when auditing app/assets/stylesheets, identifying removable SCSS partials or selectors, investigating legacy CSS, estimating dead CSS, or verifying whether a class is still used before deleting it.
---

# Analyze Unused SCSS

Find evidence-backed removal candidates without equating a failed text search with proof that a style is unused.

## Workflow

1. Read the repository instructions and CSS build command. Identify every Sass entrypoint, output bundle, load path, and layout that includes each bundle. Do not assume every file below `app/assets/stylesheets` is compiled.
2. Read each project entrypoint and recursively trace its local `@import`, `@use`, and `@forward` graph. Keep project SCSS, vendor/framework SCSS, generated CSS, and Tailwind output in separate scopes.
3. Run `scripts/analyze_scss_usage.py` from the repository root for a reproducible first pass. Supply the actual project entrypoints and relevant render/code roots. Treat its `candidate` result as a queue for manual verification, not a deletion verdict.
4. Read [references/rails-usage-patterns.md](references/rails-usage-patterns.md) completely before classifying candidates. Check ERB, Slim shorthand and dynamic attributes, ViewComponents, Rails helpers/form builders, presenters, JavaScript/TypeScript, library-generated state classes, runtime content, and relevant deletion history.
5. Inspect the complete selector, not only its class tokens. Verify ancestor/descendant relationships, combined classes, attributes, pseudo-classes, and dynamically generated BEM modifiers. Compile the entrypoint to a temporary path when Sass nesting makes the emitted selector unclear.
6. Group results by source partial and classify each selector as `used`, `safe removal`, `likely unused`, or `inconclusive`. Require positive evidence for `safe removal`.
7. Report findings only unless the user explicitly asks for deletion. If deleting, remove the smallest verified selector or import, rebuild CSS, run targeted UI/system tests, lint SCSS, and inspect the diff.

## First-pass scanner

Run from the target repository root:

```bash
python3 .agents/skills/analyze-unused-scss/scripts/analyze_scss_usage.py \
  --entrypoint app/assets/stylesheets/main.scss \
  --search-root app \
  --search-root engines \
  --only candidates
```

The scanner:

- resolves only local Sass imports below the stylesheet root;
- reports local SCSS files unreachable from the selected entrypoints;
- expands common nested selectors such as `&__item` and `&--active`;
- checks class tokens across Rails templates, Ruby render code, and JavaScript/TypeScript;
- marks a selector as a candidate when at least one required class token has no literal hit.

Use `--format json` when further filtering or aggregation is useful. Use `--only all` to audit the scanner's positive matches and dynamic-selector warnings.

## Evidence standard

Classify `safe removal` only when all of the following hold:

- the selector is emitted by a currently loaded project bundle;
- at least one necessary part of the complete selector cannot occur;
- exact, shorthand, helper-generated, and dynamic class construction searches are negative;
- no JavaScript, third-party widget, rich-text/runtime content, or state machine owns the class;
- the owning feature or DOM structure is absent, or rendered-page evidence confirms absence;
- version history positively links the selector to removed markup when such history is available;
- tests/previews/fixtures are not the only reason it appears used.

Use `likely unused` when repository evidence is negative but runtime generation remains plausible. Use `inconclusive` for generic state classes, vendor selectors, dynamic interpolation, CMS/rich-text hooks, or selectors whose DOM relationship cannot be established statically.

## Report format

For each finding include:

- bundle and source partial;
- complete emitted or expanded selector;
- relevant class tokens and searches performed;
- usage evidence or reason no usage can occur;
- confidence classification and runtime caveats;
- recommended smallest removal and verification step.

Also list unreachable local partials separately: an unreachable file is excluded from the current bundle, not necessarily obsolete.
