# frozen_string_literal: true

module CourseService
module Structure # rubocop:disable Layout/IndentationWidth
  ##
  # This class builds scopes to get the items visible to a user inside the
  # course content tree. It provides methods to get different scopes for items
  # or items nodes, possibly more in the future.
  #
  # It currently supports regular sections, as well as content tests.
  #
  class UserItemsSelector
    def initialize(node, user_id)
      # Assert parameters are non-null to early abort and to give a specific
      # error message.
      raise ArgumentError.new('node required') if node.blank?
      raise ArgumentError.new('user_id must be present') if user_id.blank?

      @node = node
      @user_id = begin
        UUID(user_id)
      rescue TypeError
        # The user_id is no UUID, e.g. as for an anonymous user.
        # In this case, do not assign the user to a branch, do not join
        # restricted branches below, and therefore ignore all branch items.
      end
    end

    ##
    # This method retrieves the actual "domain" items. If you are just
    # interested in the item nodes, you could just call #item_nodes instead.
    # The `scope` allows to apply the scopes needed to filter items for
    # different use cases.
    #
    def items(scope: CourseService::Item)
      scope.joins(:node)
        .where(node: item_nodes)
        .reorder('nodes.lft ASC')
    end

    ##
    # Use this method to retrieve the visible nodes, not actual "domain" items
    # as for #items above.
    #
    def item_nodes
      # Assign the user to all content tests available in this tree (node
      # descendants) and collect the assigned group IDs. We will later use these
      # group IDs to construct a single query for visible branches.
      group_ids = if @user_id.present?
                    content_tests.map do |ct|
                      ct.group_for_user(@user_id)
                    end
                  else
                    []
                  end

      # Collect a bunch of item containers, e.g. nodes that contain items
      # visible to the given user ID. Right now, these are:
      #
      # * All items directly attached to a section.
      # * All items attached to a content test branch the user is assigned to.
      containers = []
      containers << Structure::Section.merge(@node.self_and_descendants)
      if group_ids.any?
        containers << Structure::Branch.merge(@node.self_and_descendants)
          .joins(:branch)
          .where(branches: {group_id: group_ids})
      end

      # The queries for the different items container are combined via a UNION
      # and used as `parent_id` condition. We only need to handle a few
      # container nodes here, but can fetch all item nodes in one SQL query.
      #
      # This will return all items that are *direct* descendants of any of the
      # collected container nodes from above.

      union = containers.map do |c|
        "(#{c.unscope(:order).select(:id).to_sql})"
      end.join(' UNION ')

      # Explicitly order by 'lft' to return the nodes in the correct course order.
      Structure::Item.where("nodes.parent_id IN (#{union})").reorder('lft ASC')
    end

    private

    def content_tests
      @content_tests ||= begin
        nodes = Structure::Fork.merge(@node.self_and_descendants).joins(:fork)
        ContentTest.where(id: nodes.select('forks.content_test_id'))
      end
    end
  end
end
end
