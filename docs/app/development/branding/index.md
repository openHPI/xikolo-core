# How to brand Xikolo

The Xikolo platform is capable of being adjusted to match a corporate design.

The base styles of the platform are located in `app/assets/`.
To brand the platform, you will need to make adjustments in `brand/<name>/assets`.
The following files are most important, please see the respective pages for detailed explanations.

```shell
brand/<name>/assets/fonts
brand/<name>/assets/images
brand/<name>/assets/stylesheets
```

To write brand specific locales, add a `config/locales/<name>.yml` and override the locales accordingly.
The application is able to handle more than one root key for languages.

## First steps

Add a folder in the `/brand` directory with the name of the configured brand.

!!! tip
    If your brand requires a homepage, adapt the `brand_mapping` in `app/controllers/home/home_controller.rb` and add a view in `app/views/home/home/index_<name>.html.slim`.

When switching brands, to compile the brand's specific assets before starting services, use: `BRAND=your_brand make`.

Start the services with the `BRAND=<name>` environment variable.

## Best practices

### Use `$xi-` variables for customization

These are the variables meant to be overridden for branding.

```scss
// Introducing a new override-able variable
$xi-navbar-border-color: $primary-color !default;

// Override in brand CSS
$xi-navbar-border-color: $custom-color;
```

### Use a `<name>-` prefix

When classes are definitely only used for a specific brand, add a prefix.
With more generic classes (e.g. `home-section`), it's more likely that there is accidentally shared CSS between different brands, even though their homepages look quite different.
Having such a prefix makes it clear that the CSS (and its usages in HTML) clearly belongs to the branded assets/views.

```scss
.genericBrand-container {
  padding-top: 20px;
  font-size: $xi-font-size-teaser;
}
```
