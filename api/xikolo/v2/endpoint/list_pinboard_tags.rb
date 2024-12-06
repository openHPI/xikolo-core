# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListPinboardTags < Xikolo::API
        desc 'Returns all pinboard tags for a course'
        get do
          authenticate!
          header 'Cache-Control', 'no-cache'

          context = {}
          if params[:course]
            course_service = Xikolo.api(:course)
            pinboard_service = Xikolo.api(:pinboard)

            course = course_service.value!.rel(:course).get(id: params[:course]).value!

            sections = course_service.value!.rel(:sections).get(course_id: course['id'], include_alternatives: true).value!
            items = get_paged! course_service.value!.rel(:items).get(course_id: course['id'], was_available: true).value!

            # Load sections and items
            context = {
              sections: Array.wrap(sections).to_h {|i| [i.id, i.title] },
              items: Array.wrap(items).to_h {|i| [i.id, i.title] },
            }

            tags = get_paged! pinboard_service.value!.rel(:tags).get(course_id: course['id']).value!
          elsif params[:collab_space]
            tags = get_paged! Xikolo.api(:pinboard).value!.rel(:explicit_tags).get(learning_room_id: params[:collab_space]).value!
          else
            tags = []
          end

          present :pinboard_tags, tags, with: Xikolo::Entities::PinboardTag, **context
        end
      end
    end
  end
end
