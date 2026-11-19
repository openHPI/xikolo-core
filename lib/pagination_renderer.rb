# frozen_string_literal: true

require 'will_paginate/view_helpers/action_view'

# This self-made tag building thing is no standard Rails rendering
# context, the recommended context tag changes do not work here:
#
# rubocop:disable Rails/ContentTag

class PaginationRenderer < WillPaginate::ActionView::LinkRenderer
  include ActionView::Helpers::OutputSafetyHelper

  protected

  def page_number(page)
    if page == current_page
      tag(:li, tag(:span, page, class: 'x-join-item x-btn x-btn-primary x-btn-active', 'aria-current': 'page'))
    else
      tag(:li, link(page, page, class: 'x-join-item x-btn', rel: rel_value(page)))
    end
  end

  def previous_or_next_page(page, text, classname)
    if page
      tag(:li, link(text, page, class: "x-join-item x-btn #{classname}".strip))
    else
      tag(:li, tag(:button, text, class: "x-join-item x-btn x-btn-disabled #{classname}".strip,
        disabled: true, 'aria-disabled': true))
    end
  end

  def html_container(html)
    tag(:ul, html, class: 'x-join flex flex-wrap justify-center')
  end

  def gap
    tag(:li, tag(:button, '…', class: 'x-join-item x-btn x-btn-disabled', disabled: true, 'aria-hidden': 'true'))
  end

  def previous_page
    previous_or_next_page(
      @collection.current_page > 1 && (@collection.current_page - 1),
      '<span class="xi-icon fa-regular fa-chevron-left ms-5"></span>' \
      "#{I18n.t(:'pinboard.pagination.previous')}",
      ''
    )
  end

  def next_page
    previous_or_next_page(
      @collection.current_page < total_pages && (@collection.current_page + 1),
      "#{I18n.t(:'pinboard.pagination.next')}" \
      '<span class="xi-icon fa-regular fa-chevron-right me-5"></span>',
      ''
    )
  end
end

# rubocop:enable all
