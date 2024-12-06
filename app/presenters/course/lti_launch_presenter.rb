# frozen_string_literal: true

class Course::LtiLaunchPresenter
  def initialize(item, user)
    @item = item
    @launch = item.content.launch_for(user)
  end

  def page_title
    "#{@item.title} | #{Xikolo.config.site_name}"
  end

  def headline
    @item.title
  end

  def info
    if form_target == '_blank'
      I18n.t(:'items.lti.wait_message_new_window')
    else
      I18n.t(:'items.lti.wait_message_same_window')
    end
  end

  def url
    @launch.target_url
  end

  def form_target
    {
      'pop-up' => '_blank',
      'window' => '_self',
      'frame' => '_self',
    }[@launch.presentation_mode]
  end

  def data
    @launch.data_hash
  end
end
