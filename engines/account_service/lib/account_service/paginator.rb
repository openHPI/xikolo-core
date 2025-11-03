# frozen_string_literal: true

module AccountService
  class Paginator < PaginateResponder::WillPaginateAdapter
    attr_reader :field, :key

    def initialize(responder, field, key: :id)
      super(responder)

      @field    = field
      @key      = key
      @original = responder.resource
    end

    def paginate
      resource = self.resource.reorder(field => :asc, key => :asc)

      if page.is_a?(UUID4)
        _paginate(resource)
      else
        resource.paginate(page:, per_page:)
      end
    end

    def total_count
      @original.except(:select).count
    end

    def next_page
      # .count breaks AR with Cannot visit Arel::SelectManager
      # This does not happen on selects so we collect IDs an count them
      resource.last.id.to_s if resource.to_a.size >= per_page && resource.last
    end

    def prev_page
      if page.is_a?(UUID4)
        page.to_s
      else
        super
      end
    end

    def cast_page(page)
      UUID4.try_convert(page) || Integer(page)
    end

    private

    def _paginate(relation)
      _paginate_filter(relation.limit(per_page))
    end

    def _paginate_filter(relation)
      relation.where field_column.gt(field_value).or \
        field_column.eq(field_value).and(key_column.gt(key_value))
    end

    def field_value
      _t.project(field_column).where(key_column.eq(key_value)).take(1)
    end

    def key_value
      page.to_s
    end

    def field_column
      _t[field]
    end

    def key_column
      _t[key]
    end

    def _t
      resource.arel_table
    end
  end
end
