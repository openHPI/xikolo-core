# frozen_string_literal: true

module Xikolo
  module Endpoint
    module Types
      class Type
        def initialize(**_opts); end

        def out(_)
          raise NotImplementedError
        end

        def in(_)
          raise NotImplementedError
        end

        def name
          self.class.name.demodulize.downcase
        end

        def schema
          nil
        end
      end
    end
  end
end
