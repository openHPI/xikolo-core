# frozen_string_literal: true

require 'active_support/concern'

module AttachFile
  extend ActiveSupport::Concern

  def attach_file(locator = nil, path, **kwargs) # rubocop:disable Style/OptionalArguments
    results = all(:file_field, locator, **kwargs, visible: :all)

    # If any possible connected "file input" is a S3-dropzone hidden
    # input we must make it visible before being able to interact with it.
    if results.any? {|e| e['class'] == 'dz-hidden-input' }
      kwargs[:make_visible] = {
        'visibility' => 'visible',
        'position' => 'inherit',
        'top' => 'auto',
        'right' => 'auto',
        'bottom' => 'auto',
        'left' => 'auto',
        'height' => 'auto',
        'width' => 'auto',
      }
    end

    super
  end
end

RSpec.configure do |config|
  config.include AttachFile, type: :feature
end
