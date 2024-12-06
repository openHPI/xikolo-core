# frozen_string_literal: true

module AssignmentRules
  class RoundRobinAssignmentRule < AssignmentRule
    # rubocop:disable Rails/SkipsModelValidations
    def assign(num_groups: 2)
      user_test.round_robin_counter.tap do |current_value|
        user_test.update_attribute(
          :round_robin_counter,
          (current_value + 1) % num_groups
        )
      end
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
