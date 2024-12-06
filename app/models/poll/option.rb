# frozen_string_literal: true

module Poll
  class Option < ::ApplicationRecord
    self.table_name = 'poll_options'

    validates :text, :position, presence: true
    validates :position, uniqueness: {scope: :poll_id}

    belongs_to :poll

    default_scope { order(position: :asc) }

    before_validation :ensure_position_has_value
    before_destroy :ensure_poll_is_open

    private

    def ensure_poll_is_open
      return if poll.start_at.future?

      errors.add(:poll, :open)
      throw(:abort)
    end

    def ensure_position_has_value
      if !position
        # If no position is given, move it to the end
        self.position = (other_options.maximum(:position) || 0) + 1
      elsif other_options.exists?(position:)
        # If the given option is taken, increment the position of all options
        # with higher positions to preserve uniqueness
        # rubocop:disable Rails/SkipsModelValidations
        other_options
          .where(position: position..)
          .reorder(position: :desc)
          .each {|option| option.increment!(:position) }
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    def other_options
      if persisted?
        poll.options.where.not(id:)
      else
        poll.options
      end
    end
  end
end
