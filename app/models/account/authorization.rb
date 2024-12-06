# frozen_string_literal: true

module Account
  class Authorization < ::ApplicationRecord
    belongs_to :user, optional: true
  end
end
