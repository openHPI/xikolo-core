# Rails SCSS Usage Verification

## Contents

- Build and import scope
- Static class sources
- Dynamic and generated classes
- Selector-level reasoning
- Version-history evidence
- Runtime verification
- Removal verification

## Build and import scope

Read the build script, not only filenames that look like manifests. Record:

- Sass entrypoint to output bundle mappings;
- Sass load paths;
- layouts or pages that include each output;
- repeated imports and imports shared across bundles;
- third-party sources from `node_modules`, `vendor`, gems, or engines;
- separately generated Tailwind or other CSS.

Trace quoted `@import`, `@use`, and `@forward` directives recursively. Sass may resolve `name` to `_name.scss`, `name.scss`, or an index file. An SCSS file can be present but unreachable; an imported file can emit nothing because it only defines variables or mixins.

For Xikolo, start with `bin/build_sass`, `app/assets/stylesheets/main.scss`, `_global.scss`, `_partials.scss`, `_components.scss`, `libs.scss`, and `bootstrap-custom.scss`. Confirm these remain current rather than hard-coding them as universal Rails conventions.

## Static class sources

Search at least these sources:

- ERB: `class="..."`, `class:`, hashes passed to helpers, arrays, `class_names`, and `token_list`;
- Slim: `.class` shorthand, `tag.class`, `class=`, `class =`, helper option hashes, and interpolated attributes;
- ViewComponent templates and their Ruby classes;
- helpers, presenters, decorators, form objects/builders, inputs, mailers when relevant, and model methods returning CSS classes;
- JavaScript/TypeScript HTML strings, template literals, `className`, `classList`, jQuery `addClass`/`removeClass`/`toggleClass`, and selector queries;
- previews, specs, fixtures, and snapshots as secondary evidence only.

Useful exact searches include:

```bash
rg -n --hidden --glob '!app/assets/stylesheets/**' --glob '!app/assets/builds/**' \
  '(class|className|css_classes|class_names|token_list|classList|addClass|removeClass|toggleClass)'
rg -n --fixed-strings 'candidate-class' app engines spec
```

Use token boundaries or fixed-string searches. A hit in prose, a translation, a different stylesheet, or a similarly named identifier is not usage.

## Dynamic and generated classes

Search stable fragments when an exact class is absent. Typical forms include:

- `"flash--#{type}"` or `` `x-progress-${state}` ``;
- arrays/hashes of modifiers joined at render time;
- component methods such as `css_classes`, `css_modifiers`, or `classes`;
- state classes toggled by Stimulus, jQuery, Turbo, Dropzone, Bootstrap, or another widget;
- form-builder classes such as validation, field-type, and error states;
- sanitized rich text, CMS-authored HTML, remote service payloads, and persisted HTML;
- library-owned markup whose class names exist only in package sources.

Map the allowed value set when possible. A dynamic prefix proves only that some classes can be generated; verify that the candidate suffix is reachable. Search Ruby enums/constants, translation-driven variants, data attributes, controller values, and API response mappings.

Generic classes such as `active`, `open`, `disabled`, `in`, `error`, or `selected` require context. A literal hit elsewhere does not prove the selector's required DOM relationship exists.

## Selector-level reasoning

Reason about the complete selector:

- `.card.active` requires both classes on one element.
- `.card .active` requires an active descendant of a card.
- `.card > .title` requires the direct-child relationship.
- `.field[aria-invalid="true"]` requires the class and attribute state.
- `.menu:hover .icon` may be used even though `hover` never appears in templates.
- `.block { &__item { ... } }` emits `.block__item`; search the emitted class.
- comma-separated selectors are separate removal units.

Do not mark an entire rule unused merely because one selector in a comma-separated list is unused. Do not treat pseudo-classes/elements as template tokens. Check Sass loops and interpolation by compiling when their emitted names are not obvious.

Compile to a temporary file instead of overwriting checked-in/generated assets. Reproduce load paths from the build script, for example:

```bash
bun sass app/assets/stylesheets/main.scss /private/tmp/xikolo-styles.css \
  --no-source-map --load-path=node_modules --load-path=vendor --no-error-css
```

Adapt the command to the current build script and chosen entrypoint.

## Version-history evidence

Use version history as supporting positive evidence when the current tree is silent:

```bash
git log -S'candidate-class' --all --oneline -- app
git log -G'candidate-class' --all --oneline -- app
git show <commit> --stat --oneline
git show <commit> -- path/to/owning/view path/to/stylesheet
```

Look for the commit that removed or migrated the last owning renderer. Distinguish a deliberate feature/component migration from a rename, move, or temporary deletion. History strengthens a current-tree finding but does not override current runtime generation, persisted content, or a class reintroduced under another construction.

## Runtime verification

Use rendered-page or system-test evidence for high-value or ambiguous removals:

1. Identify routes and states that own the partial.
2. Render authenticated/unauthenticated, validation-error, empty, loading, expanded, responsive, and permission-dependent states as applicable.
3. Inspect DOM classes, including those added after interaction.
4. Search browser-loaded stylesheets or coverage results only as supporting evidence; route coverage is never complete by default.
5. Confirm that classes are not injected by a third-party component after initialization.

CSS coverage reports what a particular session exercised, not what the application can render. State the tested routes, roles, viewport sizes, and interactions.

## Removal verification

After an explicitly requested removal:

1. Delete the narrowest verified selector, rule, or now-empty import.
2. Rebuild every affected bundle.
3. Run SCSS linting and targeted request/component/system tests.
4. Inspect compiled-size change when useful.
5. Run `git diff --check` and review the stylesheet diff for accidental formatting or generated-file changes.

Keep uncertain candidates in the report. Do not add ignore comments or safelists merely to silence the analysis.
