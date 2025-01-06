# frozen_string_literal: true

module ApplicationHelper
  def current_controller?(controller_name)
    params[:controller] == controller_name
  end

  def browser_support
    @browser_support ||= BrowserSupport.new(browser)
  end

  def hide_browser_warning?
    @in_app || cookies[:_browser_warning] == 'hide' # rubocop:disable Rails/HelperInstanceVariable
  end

  def imagecrop(image_url, query_params = {})
    Imagecrop.transform(
      image_path(image_url),
      query_params
    )
  end

  def advanced_settings(column_offset: 2, &block)
    id = SecureRandom.uuid

    capture do
      concat advanced_settings_button(id, column_offset)
      concat tag.div(capture(&block), id:)
    end
  end

  def advanced_settings_button(id, column_offset)
    show_text = I18n.t :'buttons.show_advanced_settings'
    hide_text = I18n.t :'buttons.hide_advanced_settings'

    tag.div do
      tag.button(show_text, class: "btn-xs btn btn-default col-lg-offset-#{column_offset} mb15",
        'data-behavior': 'toggle-visibility',
        data: {
          'toggle-visibility': id,
          'toggle-text-on': show_text,
          'toggle-text-off': hide_text,
        },
        type: 'button')
    end
  end
end
