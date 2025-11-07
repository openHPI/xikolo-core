# frozen_string_literal: true

class Account::AccountForm < XUI::Form
  self.form_name = 'user'

  attribute :full_name, :single_line_string
  attribute :born_at, :date
  attribute :status, :single_line_string
  attribute :email, :single_line_string
  attribute :password, :single_line_string
  attribute :password_confirmation, :single_line_string
  attribute :language, :single_line_string

  validates :full_name,
    :born_at,
    :status,
    :email,
    :password,
    :password_confirmation,
    :language,
    presence: true
  validates :password, confirmation: true
end
