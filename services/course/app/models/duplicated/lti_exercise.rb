# frozen_string_literal: true

module Duplicated
  class LtiExercise < ApplicationRecord
    belongs_to :lti_provider, class_name: '::Duplicated::LtiProvider'
  end
end
