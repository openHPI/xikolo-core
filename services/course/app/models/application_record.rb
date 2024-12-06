# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # We're removing `#to_json` and `#as_json` here from all models
  # to ensure models are not directly used for serialization.
  #
  # An exception will be raised when a model is tried to be rendered or
  # used undecorated e.g. due to a forgotten `#decorate_assocization`.
  #
  undef_method :to_json
  undef_method :as_json
end
