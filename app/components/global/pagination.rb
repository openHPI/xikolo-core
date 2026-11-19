# frozen_string_literal: true

module Global
  # This component wraps the `will_paginate` helper, using the
  # custom `PaginationRenderer` to provide a consistent
  # pagination UI across the application.
  #
  # @param pagination [Object]
  #   A paginated collection object compatible with `will_paginate`
  #   (for example, an ActiveRecord relation returned by `.paginate`).
  class Pagination < ApplicationComponent
    def initialize(pagination)
      @pagination = pagination
    end

    def render?
      @pagination.total_entries.positive?
    end

    def pagination_info(pagination)
      first = pagination.offset + 1
      last = [first + pagination.per_page - 1, pagination.total_entries].min
      t(:'components.pagination.info', from: first, to: last, total: pagination.total_entries)
    end
  end
end
