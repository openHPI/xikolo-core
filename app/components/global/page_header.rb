# frozen_string_literal: true

module Global
  class PageHeader < ApplicationComponent
    TITLE_SIZES = {
      default: 'text-xl sm:text-3xl',
      slim: 'text-sm sm:text-lg',
    }.freeze
    private_constant :TITLE_SIZES

    def initialize(title, lang: nil, subtitle: nil, breadcrumbs: [], back_url: nil, type: nil)
      @title = title
      @lang = lang
      @subtitle = subtitle
      @breadcrumbs = breadcrumbs
      @back_url = back_url
      @type = type
    end

    renders_one :item_header
    renders_one :navigation

    private

    # Content inside the header can adapt to it via --page-header-bg and --page-header-text.
    def header_classes
      if navigation?
        '[--page-header-bg:var(--color-accent-25)] [--page-header-text:var(--color-accent-content)]'
      else
        '[--page-header-bg:var(--color-accent)] [--page-header-text:var(--color-white)]'
      end
    end

    def padding_classes
      navigation? ? 'pt-8 pb-4 sm:pt-16 sm:pb-8' : 'py-8 sm:py-16'
    end

    def back_link?
      @back_url.present?
    end

    # The item header carries the h1 of the page.
    # Use a p tag in this case to avoid multiple h1 tags on the page.
    def title_tag
      item_header? ? :p : :h1
    end

    def title_classes
      return 'sr-only' if navigation?

      "#{TITLE_SIZES.fetch(@type, TITLE_SIZES[:default])} font-medium wrap-anywhere"
    end
  end
end
