# frozen_string_literal: true

module Facets
  module Tracing
    extend ActiveSupport::Concern

    included do
      prepend Overlay
    end

    module Overlay
      def call(*)
        meta = {
          class: self.class.to_s,
        }

        ::Mnemosyne.trace('app.operation.call', meta:) { super }
      end
    end
  end
end
