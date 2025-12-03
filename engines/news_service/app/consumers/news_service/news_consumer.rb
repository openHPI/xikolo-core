# frozen_string_literal: true

module NewsService
class NewsConsumer < Msgr::Consumer # rubocop:disable Layout/IndentationWidth
  # this is for state and recipient number update from the notification service
  def update_state
    payload = @message.payload
    @message.ack
    uuid = UUID(payload.fetch(:news_id)).to_s
    News.find(uuid).update(payload.except(:news_id))
  end
end
end
