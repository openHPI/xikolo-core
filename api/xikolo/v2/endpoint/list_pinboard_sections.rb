# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListPinboardSections < Xikolo::API
        desc 'List all the sections for a course'
        get do
          authenticate!
          header 'Cache-Control', 'no-cache'

          course = Xikolo.api(:course).value!.rel(:course).get({id: params[:course]}).value!

          sections = Xikolo.api(:course).value!.rel(:sections).get({
            course_id: course['id'],
            include_alternatives: true,
            published: true,
            available: true,
          }).value!

          # Always add the "Technical Issues" section to the list of selectable sections
          unless Xikolo.config.disable_technical_issues_section
            sections.unshift OpenStruct.new(
              'id' => '0',
              'shortUuid' => 'technical_issues',
              'title' => I18n.t('pinboard.filters.technical_issues')
            )
          end

          present :pinboard_section, sections, with: Xikolo::Entities::Section
        end
      end
    end
  end
end
