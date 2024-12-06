# Initializers

For complex customization beyond styling and visuals, additional Ruby code may be necessary.

Brands can register custom [Rails initializers](https://guides.rubyonrails.org/configuring.html#initializers). These are scripts that will be executed once when the app server starts up, so they are a good place for configuring or registering system components.

Initializers are `.rb` files and must be placed in `brand/<name>/initializers/*.rb` - Xikolo will then load them automatically at startup.
