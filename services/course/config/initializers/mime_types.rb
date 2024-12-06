# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register 'application/msgpack', :msgpack, ['application/x-msgpack']
Mime::Type.register 'application/signed-exchange', :sxg
Mime::Type.register 'image/avif', :avif
Mime::Type.register 'image/webp', :webp
Mime::Type.register 'image/apng', :apng

ActionController::Renderers.add :msgpack do |obj, opts|
  send_data obj.to_msgpack(opts), type: Mime[:msgpack]
end
