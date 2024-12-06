# frozen_string_literal: true

module ItemTypes
  class Base
    def time_effort
      raise NotImplementedError('Method must be implemented in the subclass!')
    end
  end
end
