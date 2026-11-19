# frozen_string_literal: true

class Home::AboutController < Abstract::FrontendController
  def show
    set_page_title(t(:'header.meta_tags.about.title', site_name: Xikolo.config.site_name))
  end
end
