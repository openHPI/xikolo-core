# frozen_string_literal: true

require 'digest/bubblebabble'

module Certificate
  class Record < ::ApplicationRecord
    # Define certificate types to be reused elsewhere.
    COP = 'ConfirmationOfParticipation'
    ROA = 'RecordOfAchievement'
    CERT = 'Certificate'
    TOR = 'TranscriptOfRecords'
    TYPES = [COP, ROA, CERT, TOR].freeze

    # Map "type" column values to concrete subclasses.
    # NOTE: This can be used to map obsolete values to newer classes, or when
    # renaming models.
    STI_TYPE_TO_CLASS = {
      'Certificate' => '::Certificate::Certificate',
      'RecordOfAchievement' => '::Certificate::RecordOfAchievement',
      'ConfirmationOfParticipation' => '::Certificate::ConfirmationOfParticipation',
      'TranscriptOfRecords' => '::Certificate::TranscriptOfRecords',
    }.freeze

    # What "type" should be used when storing each subclass?
    STI_CLASS_TO_TYPE = {
      'Certificate::Certificate' => 'Certificate',
      'Certificate::RecordOfAchievement' => 'RecordOfAchievement',
      'Certificate::ConfirmationOfParticipation' => 'ConfirmationOfParticipation',
      'Certificate::TranscriptOfRecords' => 'TranscriptOfRecords',
    }.freeze

    validates :type, inclusion: {in: TYPES, message: '%{value} is not a valid record type'}
    validate :user_entitlement, :record_availability

    belongs_to :user, class_name: 'Account::User'
    belongs_to :course, class_name: 'Course::Course'
    belongs_to :template,
      class_name: 'Certificate::Template',
      inverse_of: :records,
      optional: true

    before_save :add_verification_hash

    default_scope { where(preview: false) }

    class << self
      ##
      # Resolve the concrete subclass to use for a value of the type column.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#find_sti_class.
      def find_sti_class(type_name)
        if (cls = STI_TYPE_TO_CLASS[type_name])
          cls.constantize
        else
          raise SubclassNotFound.new("Unsupported record type: #{type_name}")
        end
      end

      ##
      # Determine the type identifier to use as "type" when storing a concrete subclass.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#sti_name.
      def sti_name
        STI_CLASS_TO_TYPE.fetch(name)
      end
    end

    # For some time, the same verification codes were generated for CoPs and RoAs
    # Record verification should always return the "most valuable" record for
    # those records
    # Courses with Transcript of Records shall not have other certificate types at all
    scope :by_code, lambda {|code|
      where(verification: code).order(Arel.sql(<<~SQL.squish)).limit(1)
        CASE type
          WHEN 'Certificate' THEN 1
          WHEN 'RecordOfAchievement' THEN 2
          ELSE 3
        END
      SQL
    }

    def self.verify(verification_code)
      record = by_code(verification_code).take!
      RecordPresenter.new(record, :verify)
    end

    def add_verification_hash
      return if verification.present?

      self.verification = create_hash[0..28]
    end

    def render_data
      RenderDataPresenter.new(self, template)
    end

    def enrollment
      @enrollment ||= Xikolo.api(:course).value!.rel(:enrollments).get(
        course_id:,
        user_id:,
        deleted: true,
        learning_evaluation: true
      ).value!.first
    end

    private

    # for validation: check if user was ever enrolled to the course
    # and has earned requested record type
    def user_entitlement
      return if enrollment.present? && enrollment.dig('certificates', type&.underscore).present?

      errors.add(:base, :user_entitlement)
    end

    # for validation: check if record is already available
    def record_availability
      return if course.records_released && template.present?

      errors.add(:base, :record_availability)
    end

    def create_hash
      token = user_id + course_id + type
      hash =  Digest::SHA256.bubblebabble token
      filter_forbidden_words(hash, token)
    end

    # There was a user complaint about a "penis-mamas" verification, so lets
    # modify the verification hash if strings like that occur. Additional
    # forbidden words can be added as required. Affected records must be
    # deleted to enforce recreation.
    def filter_forbidden_words(hash, token)
      hash_offset = 0

      while hash_contains_forbidden_words(hash)
        hash_offset += 1
        hash = Digest::SHA256.bubblebabble token + hash_offset.to_s
      end

      hash
    end

    def hash_contains_forbidden_words(hash)
      forbidden_words = Xikolo.config.certificate['forbidden_verification_words']
      (forbidden_words - hash.split('-')).length < forbidden_words.length
    end
  end
end
