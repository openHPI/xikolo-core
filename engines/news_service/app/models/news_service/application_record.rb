# frozen_string_literal: true

module NewsService
class ApplicationRecord < ActiveRecord::Base # rubocop:disable Layout/IndentationWidth
  self.abstract_class = true
end
end
