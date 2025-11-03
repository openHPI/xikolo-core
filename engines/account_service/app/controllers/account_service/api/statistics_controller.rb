# frozen_string_literal: true

module AccountService
class API::StatisticsController < API::BaseController # rubocop:disable Layout/IndentationWidth
  self.responder = Responders::API

  respond_to :json

  def show
    expires_in 1.hour, public: true

    respond_with Statistics.take
  end

  def decorate(obj)
    # There is no decorator for statistics
    obj
  end
end
end
