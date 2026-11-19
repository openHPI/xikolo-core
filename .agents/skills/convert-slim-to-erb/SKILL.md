---
name: convert-slim-to-erb
description: Safely convert Rails view templates from `*.html.slim` to behaviorally equivalent `*.html.erb` files. Use when migrating one or more Slim views, partials, layouts, mailer templates, or ViewComponent templates to ERB while preserving rendered HTML, Ruby control flow, helper behavior, escaping, whitespace, styling, and translations exactly.
---

# Convert Slim to ERB

Perform a template-language-only refactor. Preserve observable behavior and rendered markup; do not redesign, clean up, or modernize the view during conversion.

## Establish the contract

1. Resolve the exact `*.html.slim` files in scope.
2. Read each complete template before editing. Inspect related partials, components, helpers, and tests when needed to understand block structure or rendering behavior.
3. Check the working tree and preserve unrelated user changes. Never overwrite an existing `*.html.erb` counterpart.
4. Identify a relevant rendering, component, request, or system spec to run before and after the conversion. If no useful coverage exists for risky behavior, add the narrowest characterization test first.
5. Convert one logical template group at a time so each diff remains reviewable.

Treat all of the following as behavior:

- element names, nesting, order, and void-element handling;
- IDs, classes, attributes, `data-*` and `aria-*` values;
- helper calls, arguments, blocks, locals, and partial paths;
- conditionals, loops, assignments, captures, and `content_for` regions;
- escaped versus raw output;
- translations and user-visible text;
- whitespace where it can affect inline text, email output, `<pre>`, scripts, or styles;
- comments intentionally emitted into the response.

## Translate syntax without refactoring

Use explicit HTML tags and ERB delimiters while retaining the original structure.

- Translate Slim `=` to escaped ERB output with `<%= ... %>`.
- Translate Slim `-` to non-output Ruby with `<% ... %>`.
- Preserve Slim `==` as raw output, normally with `<%== ... %>`. Do not replace or remove an existing `raw`, `safe_join`, or `html_safe` call.
- Close every Ruby block with `<% end %>` at the same logical nesting level.
- Use output ERB for helpers whose blocks return markup, such as `link_to`, `form_with`, and rendered components. Preserve silent capture helpers such as `content_for` according to their existing behavior.
- Expand implicit Slim elements, IDs, and classes to explicit HTML without changing their values.
- Preserve Ruby interpolation and dynamic attributes. Do not precompute, reorder, merge, normalize, or rename them.
- Preserve boolean attributes and attribute omission behavior; `false`, `nil`, and string values are not interchangeable.
- Translate Slim text and comments according to whether they are rendered or silent.
- Preserve embedded script, style, JSON, and preformatted content byte-for-byte where practical; only change the delimiters required by ERB.
- Make whitespace introduced by Slim's whitespace-control markers explicit in ERB. Inspect adjacent inline elements and text rather than relying on indentation.
- Do not pretty-print adjacent inline elements across ERB lines when those line breaks would add text nodes. Prefer exact output over visually tidy source formatting.
- Keep multiline Ruby expressions readable, but do not alter their arguments or evaluation order.

Do not change CSS classes, convert styling systems, update helper APIs, rename locals, simplify conditionals, extract partials, rewrite copy, or fix unrelated defects. Record tempting cleanup separately.

## Preserve conditional attribute omission

Slim can omit a dynamic attribute when its value is `false`, while Rails tag helpers can serialize the same value for `data-*` attributes as `"false"`. For example:

```slim
.video-player data-videoplayer-with-transcript=transcript
```

When Slim omits this attribute for `false`, preserve that behavior in ERB:

```erb
<%= tag.div class: 'video-player', data: {videoplayer_with_transcript: transcript || nil} do %>
  ...
<% end %>
```

Passing `transcript` directly can emit `data-videoplayer-with-transcript="false"`. A presence selector such as `[data-videoplayer-with-transcript]` or `hasAttribute()` still matches it and can initialize functionality whose markup is absent.

- Inspect the original output and attribute consumers before choosing the ERB representation. Use `value || nil` only when the original omits both `false` and `nil`; preserve an intentional literal `"false"`, especially for ARIA attributes.
- Check both enabled and disabled states: assert the attribute is present when enabled and absent when disabled, rather than checking its value alone. Exercise a presence-based JavaScript consumer when relevant.
- Preserve the existing consumer contract in the template. Do not change JavaScript to compensate for a conversion regression as part of a template-only refactor.

## Handle ambiguous constructs conservatively

Pause and investigate before translating any construct whose output is uncertain, especially:

- Slim whitespace controls such as `<`, `>`, trailing or leading spaces, and inline text;
- raw-output operators or HTML-safety calls;
- splat, merged, conditional, or boolean attributes;
- nested block helpers and capture helpers;
- embedded filters such as `javascript:`, `css:`, or `ruby:`;
- mail templates and other whitespace-sensitive output.

Use a small Rails console/rendering experiment or a characterization spec to establish the current output. Do not guess. If equivalence still cannot be established, stop and explain the ambiguity instead of completing an unsafe migration.

## Replace and verify

1. Add the matching `*.html.erb` destination and remove the `*.html.slim` source only after the translation is complete.
2. Review the full diff as a rename and compare every source construct with its ERB equivalent.
3. Run `bun run herb-format` on the converted ERB templates, then review its changes to ensure formatting has not altered whitespace-sensitive output.
4. Run `bun run lint:herb` and fix only issues in the converted templates.
5. Run the selected relevant specs after conversion and compare them with the baseline result.
6. Run `git diff --check`.
7. Confirm every source file in scope is gone, every matching ERB file exists, and no unrelated files changed.

When practical, render representative states before and after and compare normalized HTML or DOM structure. Also inspect raw output whenever whitespace, escaping, email content, scripts, or styles matter; normalization can hide meaningful differences.

Report the converted files, verification commands and results, and any behavior that could not be exercised. Do not claim output equivalence based on syntax and linting alone.
