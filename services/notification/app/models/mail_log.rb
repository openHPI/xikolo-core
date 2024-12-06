# frozen_string_literal: true

class MailLog < ApplicationRecord
  validates :state,
    presence: true,
    inclusion: {in: %w[success error disabled queued]}

  validates :user_id,
    presence: true

  class << self
    def queue_if_unsent!(news_id:, user_id:, &block)
      transaction do
        find_by!(news_id:, user_id:).tap do |log|
          if log.failed?
            log.requeue!
            yield
          end
        end
      rescue ActiveRecord::RecordNotFound
        create!(news_id:, user_id:, state: 'queued').tap(&block)
      end
    end
  end

  def requeue!
    update!(state: 'queued')
  end

  def failed?
    state == 'error'
  end

  def queued?
    state == 'queued'
  end
end
