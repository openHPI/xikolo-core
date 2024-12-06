# frozen_string_literal: true

module Structure
  class Item < Node
    belongs_to :item, class_name: '::Item'

    validates :parent_id, presence: true
    validates :item_id, uniqueness: {scope: :course_id}
  end
end
