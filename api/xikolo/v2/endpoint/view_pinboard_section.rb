# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ViewPinboardSection < Xikolo::API
        desc 'Returns information about a pinboard section'
        get do
          authenticate!

          uuid = UUID params.id
          section = Xikolo.api(:course).value!.rel(:section).get({id: uuid.uuid})

          present :section, section.value!, with: Xikolo::Entities::Section
        end
      end
    end
  end
end
