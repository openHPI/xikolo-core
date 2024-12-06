# frozen_string_literal: true

module Poll
  class Stats
    def initialize(poll)
      @poll = poll
    end

    def participants
      @participants ||= @poll.responses.count
    end

    def responses
      @responses ||= @poll.options.index_with do |option|
        response_counts.fetch(option.id, 0)
      end
    end

    private

    def response_counts
      @response_counts ||= ::Poll::Poll.connection.select_all(
        <<-SQL.squish, 'Count poll responses'
          WITH choices AS (
            SELECT UNNEST(choices) as choice FROM poll_responses
            WHERE poll_id = '#{@poll.id}'
          )
          SELECT choice, COUNT(*)
          FROM choices
          GROUP BY choice
        SQL
      ).to_h {|row| [row['choice'], row['count']] }
    end
  end
end
