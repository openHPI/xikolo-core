# frozen_string_literal: true

module Xikolo
  module V2::Features
    class Features < Xikolo::Endpoint::SingularEndpoint
      entity do
        type 'features'

        id { 'features' }

        attribute('features') {
          description 'List of feature flipper\'s names'
          type :array, of: :string
          reading(&:keys)
        }
      end

      member do
        get 'Get global features' do
          authenticate!

          Xikolo.api(:account).value!.rel(:user).get({
            id: current_user.id,
          }).value!.rel(:features).get.value!
        end
      end
    end
  end
end
