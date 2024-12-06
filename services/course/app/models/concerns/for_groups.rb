# frozen_string_literal: true

module ForGroups
  extend ActiveSupport::Concern

  class_methods do
    def for_groups(user:)
      group_names = _get_groups(user)

      return where(groups: []) if group_names.blank?

      # Filters to courses that either have no groups or where groups overlap
      # with the given set, e.g. the course and the given group set have at
      # least on group in common.
      #
      # Note: The SQL function `array_length` calculates lengths on a specific
      # dimension (here: 1) and therefore returns NULL on an empty array and
      # not a numeric zero (0).
      #
      # Note: `&&` is PostgreSQLs overlap operator returning TRUE if the right-
      # and left-side arrays have at least on element in common.
      where <<~SQL.squish, group_names
        (array_length(groups, 1) IS NULL OR groups && ARRAY[?]::character varying[])
      SQL
    end

    private

    def _get_groups(user)
      Xikolo.api(:account).value!
        .rel(:groups).get(user:, per_page: 1000).value!
        .pluck('name')
    rescue StandardError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      []
    end
  end
end
