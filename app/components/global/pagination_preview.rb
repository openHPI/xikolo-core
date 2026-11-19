# frozen_string_literal: true

require 'will_paginate/array'

module Global
  class PaginationPreview < ViewComponent::Preview
    # @!group
    def default
      render Global::Pagination.new([*(1..40)].paginate(page: 2, per_page: 10))
    end

    def many_pages
      render Global::Pagination.new([*(1..1000)].paginate(page: 20, per_page: 10))
    end
    # endgroup
  end
end
