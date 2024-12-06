# frozen_string_literal: true

module Xikolo::Common
  module Restify
    require 'xikolo/common/restify/paginator'

    def paginate(request, &block)
      paginator = Paginator.new(request)

      if block
        paginator.each_item(&block)
      else
        paginator
      end
    end
  end

  ::Xikolo.extend Restify
end
