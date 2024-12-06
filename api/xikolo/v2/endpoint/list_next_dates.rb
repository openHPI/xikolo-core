# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListNextDates < Xikolo::API
        desc 'Returns next course dates (assignments, deadlines etc.) relevant to the user'
        get do
          authenticate!

          dates = Xikolo.api(:course).value!.rel(:next_dates).get(user_id: current_user.id).value!

          present :next_dates, dates, with: Xikolo::Entities::CourseDate
        end
      end
    end
  end
end
