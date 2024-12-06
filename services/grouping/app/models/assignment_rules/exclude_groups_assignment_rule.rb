# frozen_string_literal: true

##
# A decorator for other assignment rules
module AssignmentRules
  class ExcludeGroupsAssignmentRule
    def initialize(inner, excluded_groups)
      @inner = inner
      @excluded_groups = excluded_groups.map(&:to_s)
    end

    def assign(num_groups:)
      group = nil
      loop do
        group = @inner.assign(num_groups:)
        break unless @excluded_groups.include? group.to_s
      end

      group
    end
  end
end
