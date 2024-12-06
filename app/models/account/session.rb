# frozen_string_literal: true

module Account
  class Session < ::ApplicationRecord
    belongs_to :user
  end
end
