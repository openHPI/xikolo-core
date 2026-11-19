# frozen_string_literal: true

module Lti
  class Grade < ::ApplicationRecord
    self.table_name = 'lti_grades'

    belongs_to :gradebook,
      class_name: 'Lti::Gradebook',
      foreign_key: :lti_gradebook_id,
      inverse_of: :grades

    has_one :exercise, through: :gradebook

    validates :value,
      presence: true,
      numericality: {greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0}

    def score
      value * exercise.weight
    end

    def item_score
      ((gradebook.item.max_dpoints / 10) * value).round(1)
    end

    # TODO: private / after_commit

    def schedule_publication!
      PublishGradeJob.perform_later(id)
    end

    def publish!
      Xikolo.api(:course).value!.rel(:result).put(
        {
          user_id: gradebook.user_id,
          item_id: gradebook.item.id,
          points: published_score,
        },
        params: {id:}
      ).value!
    end

    private

    # Once the submission deadline has passed, the exercise still counts as
    # completed but no points are awarded.
    def published_score
      return 0 if gradebook.item.submission_deadline_passed?

      item_score
    end
  end
end
