# frozen_string_literal: true

require 'imagecrop'

module ActionView::Helpers::AssetUrlHelper
  # Extends Rails' asset path helpers to link to the imagecrop service
  prepend Imagecrop::AssetUrlExtension
end
