# frozen_string_literal: true

module Course
  class Item
    class Icon
      LTI_ICONS =
        {
          bonus: 'display-code+circle-star',
        }.freeze

      QUIZ_ICONS =
        {
          bonus: 'lightbulb-on+circle-star',
          main: 'money-check-pen',
          selftest: 'lightbulb-on',
          survey: 'clipboard-list-check',
        }.freeze

      RICHTEXT_ICONS =
        {
          assistant: 'head-side-headphones',
          chart: 'chart-column',
          chat: 'comments',
          community: 'users',
          exercise2: 'keyboard',
          external_video: 'video+circle-arrow-up-right',
          moderator: 'microphone-lines',
          youtube: 'video+circle-arrow-up-right',
        }.freeze

      class << self
        def from_resource(item)
          new({
            'content_type' => item['content_type'],
            'exercise_type' => item['exercise_type'],
            'icon_type' => item['icon_type'],
          })
        end
      end

      # @param item [Hash]
      def initialize(item)
        @item = item
      end

      def icon_class
        case @item['content_type']
          when 'lti_exercise'
            LTI_ICONS.fetch(@item['exercise_type']&.to_sym, 'display-code')
          when 'peer_assessment'
            'money-check-pen'
          when 'quiz'
            QUIZ_ICONS.fetch(@item['exercise_type']&.to_sym, 'clipboard-list-check')
          when 'rich_text'
            RICHTEXT_ICONS.fetch(@item['icon_type']&.to_sym, 'file-lines')
          when 'video'
            'video'
          else
            '' # TODO: Raise on unknown types.
        end
      end
    end
  end
end
