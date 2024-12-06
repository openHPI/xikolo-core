# frozen_string_literal: true

module Xikolo
  module Endpoint
    class Pagination
      def initialize(opts = {})
        @opts = opts
      end

      def filters(context)
        paging_hash = context.query['page']
        paging_hash = paging_hash.respond_to?(:to_hash) ? paging_hash.to_hash : {}

        @current_page = [paging_hash['number'].to_i, 1].max

        filters = {'page' => @current_page}

        # Ensure the page size is between 1 and 100, if given
        filters['per_page'] = [1, paging_hash['size'].to_i, 100].sort[1] if paging_hash['size']

        default_filters.merge filters
      end

      def amend_document(resource, context)
        current_uri = URI.parse context.request.url
        total_pages = [resource.response.headers['X_TOTAL_PAGES'].to_i, 1].max

        context.document.meta! 'current_page', @current_page
        context.document.meta! 'total_pages', total_pages

        context.document.link! 'first', uri_with_page(current_uri, 1)
        context.document.link! 'last', uri_with_page(current_uri, total_pages)
        context.document.link! 'prev', uri_with_page(current_uri, @current_page - 1) if @current_page > 1
        context.document.link! 'next', uri_with_page(current_uri, @current_page + 1) if @current_page < total_pages
      end

      private

      def default_filters
        opts = @opts

        {}.tap {|defaults|
          defaults['per_page'] = opts[:per_page] if opts[:per_page]
        }
      end

      def uri_with_page(uri, page_number)
        # Extract a hash of query params from the URI
        query_params = URI.decode_www_form(uri.query.to_s).to_h

        # Replace the current page number (if it exists) with the targeted one
        uri.query = URI.encode_www_form(
          query_params.merge('page[number]' => page_number)
        )

        uri.to_s
      end
    end
  end
end
