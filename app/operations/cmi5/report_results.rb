# frozen_string_literal: true

module Cmi5
  class ReportResults < ApplicationOperation
    DEFAULT_SCORES = {
      'http://adlnet.gov/expapi/verbs/failed' => 0,
      'http://adlnet.gov/expapi/verbs/passed' => 1,
    }.freeze

    class Unauthorized < StandardError; end

    def initialize(statements:, cmi5_item_id:, user:)
      super()

      @statements = statements
      @cmi5_item_id = cmi5_item_id
      @user = user
    end

    def call
      scores = scoring_statements
      return if scores.empty?

      item = course_item
      authorize!(item)
      return unless item.exercise_type == 'selftest' && item.max_dpoints&.positive?

      scores.each do |statement, score|
        persist_result(statement.fetch('id'), score, item)
      end
    end

    private

    def scoring_statements
      @statements.filter_map do |statement|
        next unless au_level_statement?(statement)

        default_score = DEFAULT_SCORES[statement.dig('verb', 'id')]
        next if default_score.nil?

        [statement, statement.dig('result', 'score', 'scaled') || default_score]
      end
    end

    def au_level_statement?(statement)
      statement.dig('object', 'id') == Cmi5::Item.activity_id(@cmi5_item_id)
    end

    def course_item
      CourseService::Item.find_by!(
        content_type: 'cmi5',
        content_id: @cmi5_item_id
      )
    end

    def authorize!(item)
      enrolled = CourseService::Enrollment.active.exists?(
        course_id: item.course_id,
        user_id: @user.id
      )
      raise Unauthorized unless enrolled
    end

    def persist_result(statement_id, score, item)
      result = CourseService::Result.find_or_initialize_by(id: statement_id) do |new_result|
        new_result.user_id = @user.id
        new_result.item_id = item.id
      end

      result.dpoints = (item.max_dpoints * score).round
      result.save!
    end
  end
end
