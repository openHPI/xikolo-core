# frozen_string_literal: true

module Cmi5
  class ReportingsController < Cmi5::ApplicationController
    skip_before_action :verify_authenticity_token, only: %i[create activity]
    before_action :authenticate_cmi5_token!, only: %i[create activity]

    def create
      statements = Array.wrap(statement_payload)
      return bad_request! if statements.empty?
      return bad_request! if statements.any? {|statement| !statement.is_a?(Hash) || statement['id'].blank? }
      return bad_request! if request.put? && invalid_put?(statements)

      Cmi5::ReportResults.call(
        statements:,
        cmi5_item_id: cmi5_token_payload.fetch('item_id'),
        user: current_user
      )

      if request.put?
        head :no_content
      else
        render json: statements.pluck('id'), status: :ok
      end
    rescue Cmi5::ReportResults::Unauthorized, ActiveRecord::RecordNotFound
      unauthorized!
    end

    def activity
      return bad_request! if params[:activityId].blank?

      render json: {
        objectType: 'Activity',
        id: params[:activityId],
      }, status: :ok
    end

    def agent_profile
      head :not_found
    end

    private

    def statement_payload
      request.request_parameters['_json'] || request.request_parameters
    end

    def invalid_put?(statements)
      !statements.one? || statements.first['id'] != params[:statementId]
    end
  end
end
