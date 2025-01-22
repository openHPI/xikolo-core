# frozen_string_literal: true

class Home::PagesController < Abstract::FrontendController
  def show
    translations = Page.preferred_locales(I18n.locale, Xikolo.config.locales['default'])
      .where(name: params[:id]).load

    if translations.empty?
      raise AbstractController::ActionNotFound unless current_user.allowed?('helpdesk.page.store')

      # render special view, which allow admins to create this page
      return render 'not_found', status: :not_found
    end

    # load selected language
    @page = PagePresenter.new(
      page: translations.first,
      translations: current_user.allowed?('helpdesk.page.store') ? translations : nil
    )
    set_page_title @page.title
  end
end
