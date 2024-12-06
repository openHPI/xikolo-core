# frozen_string_literal: true

module Question::Search
  extend ActiveSupport::Concern

  DICTIONARIES = {
    'en' => 'english',
    'de' => 'german',
    'fr' => 'french',
  }.freeze

  UPDATE_TEXT_SEARCH_SQL = <<~SQL.squish
    WITH
      public_answers AS (
        SELECT * FROM answers
        WHERE deleted = false
          AND workflow_state NOT IN ('blocked', 'auto_blocked')
          AND question_id = $1
      ),
      public_comments AS (
        SELECT * FROM comments
        WHERE deleted = false
          AND workflow_state NOT IN ('blocked', 'auto_blocked')
          AND (
            (commentable_type = 'Question' AND commentable_id = $1) OR
            (commentable_type = 'Answer' AND commentable_id IN (SELECT id FROM public_answers))
          )
      )
    UPDATE questions SET
      language = $2,
      tsv =
        setweight(to_tsvector($3, unaccent(coalesce(title::text, ''))), 'A') ||
        setweight(to_tsvector($3, unaccent(coalesce(text, ''))), 'B') ||
        coalesce((SELECT setweight(to_tsvector($3, unaccent(string_agg(text, ' '))), 'B') FROM public_answers), '') ||
        coalesce((SELECT setweight(to_tsvector($3, unaccent(string_agg(text, ' '))), 'B') FROM public_comments), '')
    WHERE id = $1
  SQL

  included do
    self.ignored_columns += %w[tsv]

    after_commit :schedule_search_text_update, on: %i[create update]
  end

  class_methods do
    def search(query, language: 'en')
      dictionary = DICTIONARIES.fetch(language.to_s, 'english')

      query = Arel::Nodes::NamedFunction.new('websearch_to_tsquery', [
        Arel::Nodes::BindParam.new(dictionary),
        Arel::Nodes::NamedFunction.new('unaccent', [
          Arel::Nodes::BindParam.new(query),
        ]),
      ])

      search = Arel::Nodes::InfixOperation.new \
        '@@', arel_table[:tsv], query

      rank = Arel::Nodes::NamedFunction.new \
        'ts_rank', [arel_table[:tsv], query]

      result = select(
        arel_table[:id].as('search_id'),
        rank.as('rank')
      ).where(search).arel.as('search')

      join = arel_table.create_join(
        result,
        arel_table.create_on(arel_table[:id].eq(result[:search_id]))
      )

      joins(join).order(result[:rank].desc)
    end

    def schedule_search_text_update
      pluck(:id).each {|id| UpdateQuestionSearchTextWorker.perform_async(id) }
    end
  end

  def schedule_search_text_update
    UpdateQuestionSearchTextWorker.perform_async(id)
  end

  def update_text_search_index
    language = course.language
    language = 'en' unless DICTIONARIES.key?(language)
    dictionary = DICTIONARIES[language]

    self.class.connection.update(
      UPDATE_TEXT_SEARCH_SQL
        .gsub('$1', "'#{id}'")
        .gsub('$2', "'#{language}'")
        .gsub('$3', "'#{dictionary}'"),
      'Update Text Search Index',
      []
    )
  rescue Course::NotFound # The course does not exist (anymore?)
    nil
  end
end
