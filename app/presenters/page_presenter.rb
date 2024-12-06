# frozen_string_literal: true

class PagePresenter < PrivatePresenter
  include MarkdownHelper

  def name
    @page.name
  end

  def title
    @page.title
  end

  def last_changed
    @page.updated_at
  end

  def html
    render_markdown @page.text.external, include_toc: true, escape_html: false, allow_tables: true
  end

  def existing_translations(&)
    processed_translations.each_pair(&)
  end

  def new_translations
    Xikolo.config.locales['available'].each do |locale|
      yield locale unless processed_translations.key? locale.to_s
    end
  end

  private

  def processed_translations
    @processed_translations ||= @translations.to_h do |translation|
      [translation.locale, translation.title]
    end
  end
end
