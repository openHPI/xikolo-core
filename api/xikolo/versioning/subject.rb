# frozen_string_literal: true

module Xikolo
  module Versioning
    # Represents any type that supports different versions
    module Subject
      def version(constraints = {})
        @version_constraint = Xikolo::Versioning::Constraint.from_hash constraints
      end

      def version_constraint
        @version_constraint || Xikolo::Versioning::Constraint.any
      end
    end
  end
end
