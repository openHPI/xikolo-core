# frozen_string_literal: true

module Xikolo
  module Versioning
    module Constraint
      class << self
        def from_hash(hash)
          return MaxVersionConstraint.new hash[:max] if hash[:max]

          return MinVersionConstraint.new hash[:min] if hash[:min]

          raise 'Invalid constraint: need max or min key'
        end

        def any
          AnyVersionConstraint.new
        end
      end

      class AnyVersionConstraint
        def satisfy?(_version)
          true
        end
      end

      class MaxVersionConstraint
        def initialize(max_version_number)
          @max_version = Versioning::Version.new(max_version_number)
        end

        def satisfy?(version)
          @max_version.major >= version.major
        end
      end

      class MinVersionConstraint
        def initialize(min_version_number)
          @min_version = Versioning::Version.new(min_version_number)
        end

        def satisfy?(version)
          @min_version.major <= version.major
        end
      end
    end
  end
end
