# frozen_string_literal: true

# fix syntax of union queries
class Arel::Visitors::ToSql
  # rubocop:disable Naming/MethodName
  def visit_Arel_Nodes_Union(out, collector)
    collector << '(( '
    infix_value(out, collector, ' ) UNION ( ') << ' ))'
  end

  def visit_Arel_Nodes_UnionAll(out, collector)
    collector << '( '
    infix_value(out, collector, ' ) UNION ALL ( ') << ' )'
  end
  # rubocop:enable all
end
