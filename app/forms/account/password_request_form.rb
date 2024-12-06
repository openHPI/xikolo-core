# frozen_string_literal: true

class Account::PasswordRequestForm < XUI::Form
  self.form_name = 'reset'

  attribute :email, :single_line_string
  validates :email, presence: true
end
