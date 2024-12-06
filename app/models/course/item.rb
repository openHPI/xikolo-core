# frozen_string_literal: true

module Course
  class Item < ::ApplicationRecord
    belongs_to :content,
      polymorphic: true,
      optional: true,
      dependent: :destroy
    belongs_to :section

    has_one :node,
      class_name: '::Course::Structure::Item',
      dependent: :destroy

    has_many :results,
      class_name: '::Course::Result',
      dependent: :delete_all
    has_many :visits,
      class_name: '::Course::Visit',
      dependent: :delete_all

    delegate :course, to: :section

    acts_as_list scope: :section

    STI_CLASS_TO_TYPE = {
      'lti_exercise' => ::Lti::Exercise,
      'video' => ::Video::Video,
      'rich_text' => ::Course::Richtext,
    }.freeze

    # Returns the model's class name of the corresponding content resource
    # based on the value stored in the polymorphic type column `content_type`.
    def self.polymorphic_class_for(name)
      if STI_CLASS_TO_TYPE.key?(name)
        STI_CLASS_TO_TYPE[name]
      else
        super
      end
    end

    # Is the content of this section accessible to users at this time?
    def available?
      unlocked? && published?
    end

    # Are the time constraints (start and end date) fulfilled?
    def unlocked?
      return false if effective_start_date&.future?

      if course_archived
        end_date.nil? || end_date.future?
      else
        effective_end_date.nil? || effective_end_date.future?
      end
    end

    # If this item is required for another item, is the fulfillment criterion met?
    def fulfilled_for?(user)
      if %w[rich_text video].include? content_type
        return visits.where(user: user.id).any?
      end

      return false if results.where(user: user.id).empty?
      return true if max_dpoints.zero?

      score = (::Course::Result.best_for(id, user.id).dpoints * 100).fdiv(max_dpoints).floor
      score >= Xikolo.config.required_assessment_threshold
    end

    # TODO: This needs to be fixed in a presenter to avoid N+1 queries
    def course_archived
      course.status == 'archive'
    end

    def effective_start_date
      [start_date, section.effective_start_date].compact.max
    end

    def effective_end_date
      [end_date, section.end_date].compact.min
    end

    def submission_deadline_for(user_id)
      enrollment = Enrollment.find_by(user_id:, course:)
      return self[:submission_deadline] unless enrollment&.reactivated?

      [self[:submission_deadline], enrollment.forced_submission_date].compact.max
    end
  end
end
