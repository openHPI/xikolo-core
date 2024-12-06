# frozen_string_literal: true

# This self-made tag building thing is no standard Rails rendering
# context, the recommended context tag changes do not work here:
#
# rubocop:disable Rails/ContentTag

class PaginationRenderer < WillPaginate::ActionView::LinkRenderer
  include ActionView::Helpers::OutputSafetyHelper

  protected

  def page_number(page)
    if page == current_page
      tag(:li, tag(:a, page), class: 'active')
    else
      tag(:li, link(page, page, rel: rel_value(page)))
    end
  end

  def previous_or_next_page(page, text, classname)
    if page
      tag(:li, link(text, page), class: classname)
    else
      tag(:li, tag(:a, text), class: "#{classname} disabled")
    end
  end

  def html_container(html)
    tag(:div, tag(:ul, html, container_attributes), class: 'pinboard-paginate')
  end

  def gap
    tag(:li, tag(:a, '…'), class: 'disabled')
  end

  def previous_page
    previous_or_next_page(
      @collection.current_page > 1 && (@collection.current_page - 1),
      '<span class="xi-icon fa-regular fa-chevron-left mr5"></span>' \
      "#{I18n.t(:'pinboard.pagination.previous')}",
      ''
    )
  end

  def next_page
    previous_or_next_page(
      @collection.current_page < total_pages && (@collection.current_page + 1),
      "#{I18n.t(:'pinboard.pagination.next')}" \
      '<span class="xi-icon fa-regular fa-chevron-right ml5"></span>',
      ''
    )
  end
end

# rubocop:enable all
