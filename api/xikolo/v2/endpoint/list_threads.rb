# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListThreads < Xikolo::API
        desc 'Returns all threads for a course / user'
        get do
          course = Xikolo.api(:course).value!.rel(:course).get({id: params[:course]}).value!
          in_context course['context_id']
          authenticate!

          header 'Cache-Control', 'no-cache'

          apiparams = {
            watch_for_user_id: current_user.id,
            course_id: course['id'],
            page: params[:page] || 1,
            per_page: params[:per_page] || 50,
            question_filter_order: params[:order] || 'activity',
            blocked: current_user.allowed?('pinboard.entity.block'),
          }

          apiparams[:learning_room_id] = params[:learning_room_id]
          apiparams[:search] = params[:q] if params[:q].present?
          apiparams[:tags] = Array.wrap(params[:tags]).join(',') if params[:tags].present?

          if params[:section_id].present?
            apiparams[:section_id] = if params[:section_id] == 'technical_issues'
                                       'technical'
                                     else
                                       UUID(params[:section_id]).to_s
                                     end
          end

          pinboard_api = Xikolo.api(:pinboard).value!
          threads = pinboard_api.rel(:questions).get(apiparams)
          tags = get_paged! pinboard_api.rel(:tags).get({**apiparams, page: 1, per_page: 1000}).value!

          threads = threads.value!

          meta = {
            page: apiparams[:page],
            perPage: apiparams[:per_page],
            totalPages: threads.response.headers['X_TOTAL_PAGES'].to_i,
          }

          present meta, root: :meta
          present :threads, threads,
            with: Xikolo::Entities::Thread,
            course_code: course['course_code'],
            tags:,
            section_id: params[:section_id]
        end
      end
    end
  end
end
