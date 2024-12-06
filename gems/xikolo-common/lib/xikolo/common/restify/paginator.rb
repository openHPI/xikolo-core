# frozen_string_literal: true

module Xikolo::Common::Restify
  # Offers a simple interface for handling all results of a paginated
  # Restify call
  class Paginator
    def initialize(request)
      @first_page = request
    end

    def each_item
      each_page do |page|
        page.each do |item|
          yield item, page
        end
      end
    end

    def each_page
      current_page = @first_page.value!

      loop do
        yield current_page

        break unless current_page.rel?(:next)

        current_page = current_page.rel(:next).get.value!
      end
    end
  end
end
