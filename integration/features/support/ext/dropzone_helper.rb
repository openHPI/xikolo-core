# frozen_string_literal: true

module DropzoneHelper
  # Modified source from: http://blog.paulrugelhiatt.com/rails/testing/capybara/dropzonejs/2014/12/29/test-dropzonejs-file-uploads-with-capybara.html
  def drop_in_dropzone(file_path)
    # Generate a fake input selector
    page.execute_script <<-JS
      window.dropZoneFakeFileInput = window.$('<input/>').attr({ id: 'fakeFileInput', type:'file' }).appendTo('body');
    JS

    # Attach the file to the fake input selector with Capybara
    attach_file('fakeFileInput', file_path)

    # Add the file to a fileList array
    page.execute_script <<-JS
      window.fileList = [window.dropZoneFakeFileInput.get(0).files[0]]
    JS

    # Trigger the fake drop event
    page.execute_script <<-JS
      var e = jQuery.Event('drop', { dataTransfer : { files : window.fileList } });
      $('.dropzone')[0].dropzone.listeners[0].events.drop(e);
    JS
  end

  # rubocop:disable Style/OptionalArguments
  def attach_file(locator = nil, path, **kwargs)
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
  # rubocop:enable Style/OptionalArguments
end

Gurke.configure do |c|
  c.include DropzoneHelper
end
