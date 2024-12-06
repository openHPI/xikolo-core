# frozen_string_literal: true

class AjaxPaginationRenderer < PaginationRenderer
  def link(text, target, attributes = {})
    attributes['data-remote'] = true
    super
  end
end
