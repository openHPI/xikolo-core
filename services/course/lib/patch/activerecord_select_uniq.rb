# frozen_string_literal: true

module Patch
  module ActiveRecord
    module SelectUniq
      # AR calls `select_values.uniq`. This can talk very much time when
      # e.g. the select values are complex Arel nodes.
      #
      # This patch removes `.uniq` as it is deemed as not necessary.
      #
      def build_select(arel)
        if select_values.any?
          arel.project(*arel_columns(select_values))
        else
          super
        end
      end
    end

    ::ActiveRecord::Relation.prepend SelectUniq
  end
end
