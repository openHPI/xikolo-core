# frozen_string_literal: true

module Xikolo
  module Entities
    class Section < Grape::Entity
      expose :id
      expose :position

      expose def shortUuid
        object['shortUuid'] || UUID(object['id']).to_param
      end

      expose :title
      expose :start_date
      expose :end_date
      expose :optional_section
      expose :effective_start_date
      expose :effective_end_date
      expose :pinboard_closed
    end
  end
end
