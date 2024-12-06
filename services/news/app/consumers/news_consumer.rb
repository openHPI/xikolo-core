# frozen_string_literal: true

class NewsConsumer < Msgr::Consumer
  # this is for  state and recipient number update from otification service
  def update_state
    payload = @message.payload
    @message.ack
    uuid = UUID(payload.fetch(:news_id)).to_s
    News.find(uuid).update(payload.except(:news_id))
  end
end
