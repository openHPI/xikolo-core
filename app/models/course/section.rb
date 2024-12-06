# frozen_string_literal: true

module Course
  class Section < ::ApplicationRecord
    has_one :node,
      class_name: '::Course::Structure::Section',
      inverse_of: :section,
      foreign_key: :section_id, # rubocop:disable Rails/RedundantForeignKey
      dependent: :destroy

    has_many :items, inverse_of: :section # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :forks, inverse_of: :section # rubocop:disable Rails/HasManyOrHasOneDependent
    belongs_to :course

    acts_as_list scope: :course

    def optional?
      optional_section?
    end

    # Is the content of this section accessible to users at this time?
    def available?
      unlocked? && published?
    end

    # Are the time constraints (start and end date) fulfilled?
    def unlocked?
      return false if effective_start_date&.future?
      return false if end_date&.past?

      true
    end

    def destroyable?
      items.none? && forks.none?
    end

    def effective_start_date
      [start_date, course.start_date].compact.max
    end

    def fulfilled_for?(user)
      required_items = items.where(optional: false)
      return true if required_items.empty?

      score = (required_items.count {|item| item.fulfilled_for?(user) } * 100).fdiv(required_items.size).floor
      score >= Xikolo.config.required_assessment_threshold
    end
  end
end
