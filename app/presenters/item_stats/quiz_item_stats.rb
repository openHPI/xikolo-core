# frozen_string_literal: true

module ItemStats
  class QuizItemStats < BaseStats
    def initialize(item)
      super

      @item = item
      @quiz_promise = quiz_api.rel(:quiz).get({id: item['content_id']})
      @stats_promise = quiz_api.rel(:submission_statistic).get({
        id: item['content_id'],
        embed: 'avg_submit_duration',
      })
    end

    def facts
      facts = [
        I18n.t(
          'course.admin.item_stats.quiz.submissions',
          submissions: stats['total_submissions'],
          users: stats['total_submissions_distinct']
        ),
      ]

      unless quiz['unlimited_time']
        facts << I18n.t(
          'course.admin.item_stats.quiz.time',
          seconds: stats['avg_submit_duration'].ceil,
          limit: quiz['time_limit_seconds']
        )
      end

      if @item['exercise_type'] != 'survey'
        percentage_avg = format(
          '%.2f',
          stats['avg_points'] / stats['max_points'] * 100
        )

        facts << I18n.t(
          'course.admin.item_stats.quiz.points',
          avg: format('%.2f', stats['avg_points']),
          percentage_avg:,
          max_points: stats['max_points']
        )
      end

      facts.map(&:html_safe)
    end

    def facts_icon
      'money-check-pen'
    end

    def render(ctx)
      ctx.render(
        'course/admin/item_stats/quiz',
        item_stats: self
      )
    end

    def quiz_id
      quiz['id']
    end

    def submissions?
      stats['total_submissions'].positive?
    end

    def submission_limit_exceeded?
      stats['total_submissions'] > submission_limit
    end

    def submission_limit
      Xikolo.config.quiz_item_statistics_submission_limit
    end

    def questions
      @questions ||= quiz_api.rel(:questions)
        .get({quiz_id: quiz['id'], per_page: 250}).value!
        .map do |q|
          base_stats = questions_base_stats.find {|stats| stats['id'] == q['id'] }
          TYPE_CLASS_MAPPING
            .fetch(q['type'], AnyQuestion)
            .new(q, @item, base_stats)
        end
    end

    private

    def questions_base_stats
      @questions_base_stats ||= quiz_api.rel(:submission_statistic).get({
        id: quiz_id,
        only: 'questions_base_stats',
      }).then {|stats| stats['questions_base_stats'] }.value!
    end

    def stats
      @stats ||= @stats_promise.value!
    end

    def quiz
      @quiz ||= @quiz_promise.value!
    end

    def quiz_api
      @quiz_api ||= Xikolo.api(:quiz).value!
    end

    class AnyQuestion
      def initialize(question, item, base_stats)
        @question = question
        @item = item
        @base_stats = base_stats
      end

      def id
        @question['id']
      end

      def title
        @question['text'].truncate(80)
      end

      def type
        self.class.name.demodulize.underscore
      end

      def quiz_id
        @question['quiz_id']
      end

      def quiz_exercise_type
        @item['exercise_type']
      end

      def submissions?
        [
          @base_stats['correct_submissions'],
          @base_stats['incorrect_submissions'],
          @base_stats['partly_correct_submissions'],
        ].sum > 0
      end

      def render(ctx)
        ctx.render('course/admin/item_stats/quiz_questions/unknown')
      end

      def avg_performance
        # Questions can have zero points in some cases
        return '100.00' if @base_stats['max_points'].zero?

        format(
          '%.2f',
          @base_stats['avg_points'] / @base_stats['max_points'] * 100
        )
      end

      def base_stats
        return nil if @item['exercise_type'] == 'survey'

        I18n.t(
          'course.admin.item_stats.quiz.base_stats',
          percentage_avg: avg_performance,
          correct: @base_stats['correct_submissions'],
          incorrect: @base_stats['incorrect_submissions']
        )
      end
    end

    class MultipleChoiceQuestion < AnyQuestion
      def render(ctx)
        ctx.render(
          'course/admin/item_stats/quiz_questions/multiple_choice_or_answer',
          question: self
        )
      end

      def question_mapping
        [
          {
            x: {
              type: 'collect',
              sourceKey: 'text',
            },
            y: {
              type: 'collect',
              sourceKey: 'submission_count',
            },
            marker: {
              type: 'collect',
              sourceKey: 'marker_color',
              nestedTargetKey: 'color',
            },
          },
        ].to_json
      end
    end

    class MultipleAnswerQuestion < MultipleChoiceQuestion
      def base_stats
        return nil if @item['exercise_type'] == 'survey'

        I18n.t(
          'course.admin.item_stats.quiz.base_stats_w_partly_correct',
          percentage_avg: avg_performance,
          correct: @base_stats['correct_submissions'],
          partly_correct: @base_stats['partly_correct_submissions'],
          incorrect: @base_stats['incorrect_submissions']
        )
      end
    end

    class FreeTextQuestion < AnyQuestion
      def render(ctx)
        ctx.render(
          'course/admin/item_stats/quiz_questions/free_text',
          question: self
        )
      end
    end

    class EssayQuestion < AnyQuestion
      def render(ctx)
        ctx.render(
          'course/admin/item_stats/quiz_questions/essay',
          question: self
        )
      end

      def base_stats
        nil
      end
    end

    TYPE_CLASS_MAPPING = {
      'Xikolo::Quiz::MultipleChoiceQuestion' => MultipleChoiceQuestion,
      'Xikolo::Quiz::MultipleAnswerQuestion' => MultipleAnswerQuestion,
      'Xikolo::Quiz::FreeTextQuestion' => FreeTextQuestion,
      'Xikolo::Quiz::EssayQuestion' => EssayQuestion,
    }.freeze
    private_constant :TYPE_CLASS_MAPPING
  end
end
