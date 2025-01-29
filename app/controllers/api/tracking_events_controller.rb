# frozen_string_literal: true

class API::TrackingEventsController < ActionController::API
  class TrackingEventContract < Dry::Validation::Contract
    json do
      required(:events).array do
        schema do
          required(:user).schema do
            required(:uuid).filled
          end

          required(:verb).schema do
            required(:type).filled
          end

          required(:resource).schema do
            required(:uuid).filled
            required(:type).filled
          end

          optional(:timestamp).filled(:str?)
          optional(:result).hash
          optional(:context).hash
        end
      end
    end
  end

  def create
    json = JSON.parse(request.raw_post)

    contract = TrackingEventContract.new
    result = contract.call(json)
    if result.failure?
      head :unprocessable_entity
      return
    else
      data = result.to_h
    end

    data[:events].each do |event|
      exp_api_stmt = {
        user:        event[:user],
        verb:        event[:verb],
        resource:    event[:resource],
        timestamp:   event[:timestamp] || DateTime.now.iso8601(3),
        with_result: event.fetch(:result, {}),
        in_context:  event.fetch(:context, {}).tap {|c| c['user_ip'] = request.remote_ip },
      }

      Msgr.publish(exp_api_stmt.as_json, to: 'xikolo.web.exp_event.create')
    end

    head :no_content
  end
end
