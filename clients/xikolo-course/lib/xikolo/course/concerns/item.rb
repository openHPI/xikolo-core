# frozen_string_literal: true

module Xikolo::Course::Concerns
  module Item
    extend ActiveSupport::Concern

    included do
      validates :title, :content_type, :content_id, :section_id, presence: true
    end
  end
end
