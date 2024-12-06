# frozen_string_literal: true

module Poll
  class Poll < ::ApplicationRecord
    validates :question, :start_at, :end_at, presence: true
    # NOTE: Use comparison with Rails 7
    validate do
      errors.add :end_at, :before_start_date if end_at.before? start_at
    end

    has_many :options, class_name: '::Poll::Option', dependent: :delete_all
    has_many :responses, class_name: '::Poll::Response', dependent: :delete_all

    class << self
      def started
        where(start_at: ...::Time.zone.now)
      end

      def current
        started.where('end_at > ?', ::Time.zone.now)
      end

      def upcoming_for_user(user_id)
        current.order(:start_at).where.not(
          id: ::Poll::Response.where(user_id:).select(:poll_id)
        )
      end

      def latest_first
        reorder(start_at: :desc, created_at: :desc)
      end
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Poll instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Poll')
    end

    def to_param
      id
    end

    # How many participants do we need before we start showing statistics?
    MIN_PARTICIPANTS = 20

    def vote!(choices, user_id:)
      response = responses.build(
        choices:,
        user_id:
      )

      unless open?
        response.errors.add(:poll, :closed)
        raise ActiveRecord::RecordInvalid.new(response)
      end

      response.tap(&:save!)
    end

    def response_for(user_id)
      responses.find_by(user_id:)
    end

    def add_option(attrs = {})
      options.new(attrs).tap do |option|
        if editing_allowed?
          option.save
        else
          option.errors.add(:poll, :open)
        end
      end
    end

    def stats
      @stats ||= Stats.new self
    end

    def open?
      started? && !ended?
    end

    def started?
      start_at.past?
    end

    def ended?
      end_at.past?
    end

    def editing_allowed?
      start_at.future?
    end

    def reveal_results?
      return true if ended?

      show_intermediate_results? && enough_participants?
    end

    def enough_participants?
      stats.participants >= MIN_PARTICIPANTS
    end
  end
end
