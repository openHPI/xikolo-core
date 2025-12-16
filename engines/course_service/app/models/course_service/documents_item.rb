# frozen_string_literal: true

module CourseService
class DocumentsItem < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :documents_items
  self.primary_key = %i[document_id item_id]

  belongs_to :document
  belongs_to :item
end
end
