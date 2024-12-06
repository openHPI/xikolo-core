# frozen_string_literal: true

class Admin::UserForm < XUI::Form
  self.form_name = 'user'

  attribute :email, :single_line_string
  attribute :full_name, :single_line_string
  attribute :password, :single_line_string

  attribute :confirmed, :boolean, default: false
  alias confirmed? confirmed
end
