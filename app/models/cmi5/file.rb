# frozen_string_literal: true

module Cmi5
  class File < ::ApplicationRecord
    self.table_name = 'cmi5_files'

    belongs_to :cmi5_item, class_name: 'Cmi5::Item'
    has_one_attached :file
  end
end
