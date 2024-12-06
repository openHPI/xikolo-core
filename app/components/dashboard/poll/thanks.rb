# frozen_string_literal: true

module Dashboard
  module Poll
    class Thanks < ApplicationComponent
      def initialize(poll, choices:, next_poll:, stats: nil)
        @poll = poll
        @choices = choices
        @next_poll = next_poll
        @stats = stats
      end

      private

      def reveal_results?
        @stats.present?
      end

      def summary
        if reveal_results?
          t(:'polls.widget.intermediate_results', participants: number_with_delimiter(@stats.participants))
        elsif @poll.show_intermediate_results?
          t(:'polls.widget.not_enough_participants', link: polls_archive_path)
        else
          t(:'polls.widget.poll_archive_link', link: polls_archive_path)
        end
      end
    end
  end
end
