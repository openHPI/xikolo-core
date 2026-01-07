# frozen_string_literal: true

##
# Comparison Specs DSL
#
# Some simple helpers for running a shared set of scenarios against two
# or more different implementations.
#
# Like [GitHub's Scientist](https://github.com/github/scientist), but
# for our tests.
#
module ComparisonSpecs
  module DSL
    def variant(description, &setup)
      (@comparison_variants ||= []) << {
        description:,
        setup:,
      }
    end

    def with_all(&)
      if (@comparison_variants&.count || 0) < 2
        raise format 'Comparison specs need at least two variants (currently: %d)', @comparison_variants&.count.to_i
      end

      @comparison_variants.each do |variant|
        # We want to run all scenarios for each variant
        describe variant[:description] do
          # First, inline the variant's setup code
          instance_eval(&variant[:setup])

          # Then, inline the shared scenarios
          instance_eval(&)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.extend ComparisonSpecs::DSL
end
