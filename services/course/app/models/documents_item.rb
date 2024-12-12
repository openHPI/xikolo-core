# frozen_string_literal: true

class DocumentsItem < ApplicationRecord
  self.primary_key = %i[document_id item_id]

  belongs_to :document
  belongs_to :item
end
