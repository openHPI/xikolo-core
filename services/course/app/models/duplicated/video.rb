# frozen_string_literal: true

module Duplicated
  class Video < ApplicationRecord
    has_one :visual, class_name: '::Duplicated::Visual', dependent: :nullify
    has_many :subtitles, class_name: '::Duplicated::Subtitle', dependent: :destroy
  end
end
