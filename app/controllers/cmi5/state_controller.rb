# frozen_string_literal: true

module Cmi5
  class StateController < Cmi5::ApplicationController
    REQUIRED_STATE_PARAMS = %i[activityId agent registration stateId].freeze

    skip_before_action :verify_authenticity_token, only: %i[show update] # relies on token verification
    before_action :authenticate_cmi5_token!

    def show
      return bad_request! unless valid_state_coordinates?

      # cmi5 spec: LMS must provide LMS.LaunchData with launch metadata
      if params[:stateId] == 'LMS.LaunchData'
        return render_lms_launch_data
      end

      head :not_found
    end

    # TODO: Stub until we get the requirements what to save
    def update
      return bad_request! unless valid_state_coordinates?

      head :no_content
    end

    private

    def valid_state_coordinates?
      REQUIRED_STATE_PARAMS.all? {|param| params[param].present? }
    end

    def render_lms_launch_data
      # CMI5 spec section 10.0: required fields for LMS.LaunchData
      # TODO: This is a stub
      launch_data = {
        launchMode: 'Normal',
        moveOn: 'NotApplicable',
        launchParameters: '',
        masteryScore: nil,
        launchDate: Time.current.iso8601,
        contextTemplate: {
          contextActivities: {
            grouping: [
              {
                id: params[:activityId],
                objectType: 'Activity',
              },
            ],
          },
          extensions: {
            'https://w3id.org/xapi/cmi5/context/extensions/sessionid': SecureRandom.uuid,
          },
        },
      }

      render json: launch_data, status: :ok
    end
  end
end
