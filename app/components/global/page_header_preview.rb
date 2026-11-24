# frozen_string_literal: true

module Global
  class PageHeaderPreview < ViewComponent::Preview
    include ActionView::Helpers::UrlHelper
    include SvgHelper

    COURSE_TITLE = 'Digitale Gerechtigkeit – Wie du dich für eine fairere KI-Zukunft engagieren kannst'

    def simple
      render Global::PageHeader.new('Channels', subtitle: I18n.t(:'admin.page_header'))
    end

    def course_page
      render Global::PageHeader.new(COURSE_TITLE, breadcrumbs:, type: :slim)
    end

    def course_item_page
      render_with_template(locals: {title: COURSE_TITLE, breadcrumbs:, icon_class: icon_for('Video::Video')})
    end

    def course_page_with_navigation
      render_with_template(locals: {title: COURSE_TITLE, breadcrumbs:})
    end

    def with_visual
      render_with_template(locals: {title: COURSE_TITLE, breadcrumbs:})
    end

    def course_admin_page
      render Global::PageHeader.new('Item bearbeiten', subtitle: COURSE_TITLE)
    end

    def with_additional_content
      render Global::PageHeader.new(COURSE_TITLE, breadcrumbs:, type: :slim) do
        link_to 'Go to course administration', '/', class: 'inline-flex items-center gap-1.5 text-sm'
      end
    end

    private

    def breadcrumbs
      [
        {url: '#', icon: pixelart_icon('home', css_class: 'w-4 h-4'), aria_label: I18n.t('header.navigation.home')},
        {url: '#', text: I18n.t('header.navigation.courses')},
        {url: '#', text: COURSE_TITLE},
        {url: '#', text: I18n.t('courses.nav.sections')},
      ]
    end

    def icon_for(content_type)
      ::Course::Item::Icon.from_resource({'content_type' => content_type}).icon_class
    end
  end
end
