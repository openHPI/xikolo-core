# frozen_string_literal: true

class Course::Admin::LtiProviderForm < XUI::Form
  self.form_name = 'lti_provider'

  attribute :id, :uuid
  attribute :name, :single_line_string
  attribute :description, :text
  attribute :domain, :single_line_string
  attribute :consumer_key, :single_line_string
  attribute :shared_secret, :single_line_string
  attribute :presentation_mode, :single_line_string, default: 'window'
  attribute :privacy, :single_line_string, default: 'anonymized'
  attribute :custom_fields, :text

  validates :name, :domain, :consumer_key, :shared_secret, presence: true
end
