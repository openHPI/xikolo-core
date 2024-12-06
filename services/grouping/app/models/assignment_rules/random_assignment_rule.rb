# frozen_string_literal: true

module AssignmentRules
  class RandomAssignmentRule < AssignmentRule
    def assign(num_groups: 2)
      Kernel.rand(num_groups)
    end
  end
end
