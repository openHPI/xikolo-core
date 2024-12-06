# frozen_string_literal: true

require 'uuid4'

module Xikolo
  module V2::CourseItems
    class RichTexts < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'rich-texts'

        attribute('text') {
          description 'The text content (formatted as Markdown) to be shown to the user'
          type :string
        }
      end

      member do
        get 'Retrieve a single text item' do
          authenticate!

          item = ::Course::Item.find_by(content_id: id)
          course = item&.section&.course
          not_found! unless item&.available? && course.present?

          in_context course.context_id

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          ::Course::Richtext.find(UUID(id).to_s).as_api_v2
        end
      end
    end
  end
end
