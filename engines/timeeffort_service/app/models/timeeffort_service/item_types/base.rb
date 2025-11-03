# frozen_string_literal: true

module TimeeffortService
module ItemTypes # rubocop:disable Layout/IndentationWidth
  class Base
    def time_effort
      raise NotImplementedError('Method must be implemented in the subclass!')
    end
  end
end
end
