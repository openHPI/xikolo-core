# frozen_string_literal: true

module Lti
  class Gradebook < ::ApplicationRecord
    self.table_name = 'lti_gradebooks'

    belongs_to :exercise,
      optional: true,
      class_name: 'Lti::Exercise',
      foreign_key: :lti_exercise_id,
      inverse_of: :gradebooks

    has_one :item,
      -> { where(content_type: 'lti_exercise') },
      class_name: 'Course::Item',
      dependent: :restrict_with_exception,
      foreign_key: :content_id,
      primary_key: :lti_exercise_id,
      inverse_of: false

    has_many :grades,
      class_name: 'Lti::Grade',
      dependent: :destroy,
      foreign_key: :lti_gradebook_id,
      inverse_of: :gradebook

    def highest_grade
      grades.order(value: :desc).first
    end

    ##
    # Submit a new score for this user if it is valid and the nonce is unique.
    #
    def submit!(score:, nonce:)
      grade = grades.build(value: score, nonce:)

      grade.save!
      grade.schedule_publication!

      grade
    rescue ActiveRecord::RecordInvalid
      grade
    rescue ActiveRecord::RecordNotUnique
      grade.errors.add :base, :duplicate_nonce
      grade
    end
  end
end
