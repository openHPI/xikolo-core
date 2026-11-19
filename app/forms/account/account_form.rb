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
  attribute :guardian_consent, :boolean

  validates :full_name,
    :born_at,
    :status,
    :email,
    :password,
    :password_confirmation,
    :language,
    presence: true
  # Mirror the service-side checks so invalid input is reported by the form,
  # with a translatable error, instead of coming back as a literal message
  # string from the account service.
  validates :email, format: {with: AccountService::Email::EMAIL}
  validates :full_name,
    format: {with: AccountService::User::NAME_FORMAT},
    length: {maximum: AccountService::User::NAME_MAX_LENGTH}
  validates :password, confirmation: true
  validates :guardian_consent, acceptance: {allow_nil: false}, if: :underage?
  validates :guardian_consent, absence: true, unless: :underage?

  def underage?
    AccountService::AgeOfConsent.underage?(born_at)
  end
end
