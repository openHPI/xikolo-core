# HTML styleguide

## Slim (deprecated)

To write HTML, we used to use the [slim template language](https://github.com/slim-template/slim) in our project.

Over the years, we found that it is not very beginner-friendly and lacks dev-tooling support.
It might have been a good choice earlier in the project, but nowadays, we use components with less complex views.
Therefore, we decided to move away from it and use Rails-standard `*.html.erb` in our views.

For new views, please use `*.html.erb` templates.

## Attribute order

For easier reading of code it can help to have a general attribute order in the HTML.

1. `class`
2. `id`, `name`
3. `data-*`
4. `src`, `for`, `type`, `href`, `value`
5. `title`, `alt`
6. `role`, `aria-*`

This order is taken from [Code Guide by @mdo](https://codeguide.co/#html-attribute-order).

## Translation

`t` is the translation helper used:

```example
t(:'string.identifier')
```

Please use fully qualified keys in all views.
The short form is convenient, but also very cumbersome to refactor (e.g. when renaming or moving views).

You can use `%{brand}` if you need the global portal name.

Using a symbol `(:)` for the identifier will take that the identifier is not parsed on every template render.
