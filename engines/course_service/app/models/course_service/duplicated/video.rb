# frozen_string_literal: true

module CourseService
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Video < ApplicationRecord
    self.table_name = :videos

    has_one :visual, class_name: 'CourseService::Duplicated::Visual', dependent: :nullify
    has_many :subtitles, class_name: 'CourseService::Duplicated::Subtitle', dependent: :destroy
  end
end
end
