# frozen_string_literal: true

module Course
  module Item
    class Icon
      QUIZ_ICONS =
        {
          exam: 'exam',
          survey: 'survey',
        }.freeze

      class << self
        def from_resource(item)
          new({
            'content_type' => item['content_type'],
            'exercise_type' => item['exercise_type'],
          })
        end
      end

      # @param item [Hash]
      def initialize(item)
        @item = item
      end

      def icon_class
        case @item['content_type']
          when 'QuizService::Quiz'
            QUIZ_ICONS.fetch(@item['exercise_type']&.to_sym, 'learning_material')
          when 'CourseService::Richtext'
            'text'
          when 'Video::Video'
            'video'
          else
            'learning_material'
        end
      end
    end
  end
end
