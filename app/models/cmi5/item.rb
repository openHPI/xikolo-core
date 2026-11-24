# frozen_string_literal: true

module Cmi5
  class Item < ::ApplicationRecord
    self.table_name = 'cmi5_items'

    has_one :item,
      class_name: 'CourseService::Item',
      as: :content,
      dependent: :restrict_with_exception

    has_one_attached :package # stores the raw zip
    has_many :files, class_name: 'Cmi5::File', foreign_key: :cmi5_item_id

    validates :package, size: {less_than_or_equal_to: 50.megabytes}, attached: true, content_type: :zip

    def data_script_file
      files.find_by(file_path: 'html5/data/js/data.js')
    end

    def player_aspect_ratio
      return 16.0 / 9 if player_width.blank? || player_height.blank? || player_height.zero?

      (player_width.to_f / player_height).round(4)
    end

    def self.activity_id(cmi5_item_id)
      root_url = Rails.application.routes.url_helpers.root_url(
        host: Xikolo.base_url.authority
      )

      "#{root_url}cmi5/activities/#{cmi5_item_id}"
    end
  end
end
