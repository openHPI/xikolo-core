# frozen_string_literal: true

class Account::PasswordResetForm < XUI::Form
  self.form_name = 'reset'

  attribute :id, :single_line_string
  attribute :password, :single_line_string
  attribute :password_confirmation, :single_line_string

  validates :password,
    :password_confirmation,
    presence: true
  validates :password, confirmation: true
end
