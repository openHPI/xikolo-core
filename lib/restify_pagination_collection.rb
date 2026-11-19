# frozen_string_literal: true

class RestifyPaginationCollection
  def initialize(collection)
    @collection = collection
  end

  def total_pages
    @collection.response.headers['X_TOTAL_PAGES'].to_i
  end

  def current_page
    @collection.response.headers['X_CURRENT_PAGE'].to_i
  end

  def total_entries
    @collection.response.headers['X_TOTAL_COUNT'].to_i
  end

  def per_page
    @collection.response.headers['X_PER_PAGE'].to_i
  end

  def offset
    (current_page - 1) * per_page
  end
end
