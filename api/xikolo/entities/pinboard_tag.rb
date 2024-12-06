# frozen_string_literal: true

module Xikolo
  module Entities
    class PinboardTag < Grape::Entity
      expose :id

      expose def name
        case object['referenced_resource']
          when 'Xikolo::Course::Section'
            options[:sections].fetch(object['name'], object['name'])
          when 'Xikolo::Course::Item'
            options[:items].fetch(object['name'], object['name'])
          else
            object['name']
        end
      end

      expose def type
        return 'explicit' if object['type'] == 'Xikolo::Pinboard::ExplicitTag'

        {
          'Xikolo::Course::Section' => 'section',
          'Xikolo::Course::Item' => 'item',
        }.fetch object['referenced_resource'], 'other'
      end
    end
  end
end
