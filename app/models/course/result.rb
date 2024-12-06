# frozen_string_literal: true

module Course
  class Result < ::ApplicationRecord
    belongs_to :item, class_name: '::Course::Item'
    belongs_to :user, class_name: '::Account::User'

    def self.best_for(item, user)
      where(item:, user:).order(dpoints: :desc).first
    end
  end
end
