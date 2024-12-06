# frozen_string_literal: true

module Course
  module Structure
    class Root < Node
      ##
      # Preload the entire course content tree, and set up all associations
      # for tree traversal and retrieval of content models.
      #
      def preload_tree!
        # Load all descendants in one query. (`descendants` is not memoized.)
        nodes = descendants

        # Efficiently preload their content models (one query per type).
        nodes.group_by(&:class).each do |cls, filtered_nodes|
          cls.preload_content! filtered_nodes
        end

        # And now set up the "children" associations using the previously loaded models.
        # `descendants` or respectively `nodes` is just a flat array, but we want to navigate
        # the structure as a tree.
        by_parent = nodes.group_by(&:parent_id)

        ([self] + nodes).each do |node|
          # If the node has no children, we must store an empty array for this association,
          # to prevent additional queries that would also return the empty set.
          children = by_parent[node.id] || []

          association = node.association(:children)
          association.target = children
        end

        # I am the root!
        self
      end
    end
  end
end
