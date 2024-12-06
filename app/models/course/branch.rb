# frozen_string_literal: true

module Course
  class Branch < ::ApplicationRecord
    belongs_to :group, class_name: 'Account::Group'
    has_one :node, class_name: '::Course::Structure::Branch', dependent: :destroy

    belongs_to :fork
  end
end
