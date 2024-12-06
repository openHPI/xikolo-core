# frozen_string_literal: true

module Course
  class Visit < ::ApplicationRecord
    belongs_to :item, class_name: '::Course::Item'
    belongs_to :user, class_name: '::Account::User'
  end
end
