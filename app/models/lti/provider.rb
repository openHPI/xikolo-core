# frozen_string_literal: true

module Lti
  class Provider < ::ApplicationRecord
    PRESENTATION_MODES = %i[frame pop-up window].freeze
    PRIVACY_MODES = %i[anonymized pseudonymized unprotected].freeze

    self.table_name = 'lti_providers'

    has_many :exercises, # rubocop:disable Rails/HasManyOrHasOneDependent
      class_name: 'Lti::Exercise',
      foreign_key: :lti_provider_id,
      inverse_of: :provider

    attribute :presentation_mode, :string, default: 'window'
    attribute :privacy, :string, default: 'anonymized'

    validates :consumer_key, presence: true
    validates :name, presence: true
    validates :domain, format: {with: URI::DEFAULT_PARSER.make_regexp}, presence: true
    validates :shared_secret, presence: true
    validates :presentation_mode, presence: true, inclusion: PRESENTATION_MODES.map(&:to_s)
    validates :privacy, inclusion: PRIVACY_MODES.map(&:to_s)

    scope :global, -> { where(course_id: nil) }

    def tool_consumer
      IMS::LTI::ToolConsumer.new consumer_key, shared_secret
    end

    def anonymized?
      privacy == 'anonymized'
    end

    def pseudonymized?
      privacy == 'pseudonymized'
    end
  end
end
