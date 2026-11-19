# frozen_string_literal: true

module Course
  module Item
    # The human-readable type of a course item, e.g. "Video" or "Exam".
    class TypeLabel
      # Keys of `items.type_label` by quiz exercise type
      QUIZ_LABELS = {
        'selftest' => 'self_test',
        'main' => 'graded_test',
        'bonus' => 'bonus_test',
        'exam' => 'exam',
        'survey' => 'survey',
      }.freeze

      # Keys of `items.type_label` by content type, for non-quiz items
      CONTENT_LABELS = {
        'video' => 'video',
        'rich_text' => 'rich_text',
      }.freeze

      class << self
        # @param item [CourseService::Item, Hash] anything responding to
        #   `[]` with `content_type` and `exercise_type`
        #
        # Accepts hashes because the progress page's sections still list items
        # from the progresses API. Once that call is dropped and all callers pass
        # `CourseService::Item` models, this can go in favor of taking the model.
        def from_resource(item)
          new(content_type: item['content_type'], exercise_type: item['exercise_type'])
        end
      end

      def initialize(content_type:, exercise_type:)
        @content_type = content_type
        @exercise_type = exercise_type
      end

      def text
        I18n.t("items.type_label.#{key}")
      end

      private

      def key
        if @content_type == 'quiz'
          QUIZ_LABELS.fetch(@exercise_type, 'self_test')
        else
          CONTENT_LABELS.fetch(@content_type, 'learning_material')
        end
      end
    end
  end
end
