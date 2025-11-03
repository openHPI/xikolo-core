# frozen_string_literal: true

module AccountService
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
