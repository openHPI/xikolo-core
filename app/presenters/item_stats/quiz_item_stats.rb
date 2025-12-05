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
      tables = quiz_statistic_tables

      return '' if tables.empty?

      ctx.safe_join(tables.map {|table| ctx.render(Global::Table.new(**table)) })
    end

    def quiz_statistic_tables
      questions = quiz_api.rel(:questions).get({quiz_id: quiz['id']}).value!
      questions.flat_map do |question|
        question_stats = quiz_api.rel(:submission_question_statistic).get({id: question['id']}).value!

        # Skip questions without answers (e.g., essay questions)
        next unless question_stats['answers'].is_a?(Array)

        # Calculate total submissions for this specific question
        total_question_submissions = question_stats['answers'].sum {|answer| answer['submission_count'] }

        rows = question_stats['answers'].map do |answer|
          {
            text: answer['text'],
            correct: answer['correct'] ? '✓' : '',
            user_count: answer['submission_count'],
            percentage: calculate_percentage(answer['submission_count'], total_question_submissions),
          }
        end

        {
          rows:,
          headers: [
            I18n.t('course.admin.item_stats.quiz.answer'),
            I18n.t('course.admin.item_stats.quiz.correct'),
            I18n.t('course.admin.item_stats.quiz.user_count'),
            I18n.t('course.admin.item_stats.quiz.percentage'),
          ],
          title: question_stats['text'],
        }
      end.compact
    end

    private

    def calculate_percentage(user_count, total)
      return '0.00%' if total.zero?

      format('%.2f%%', (user_count.to_f / total) * 100)
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
  end
end
