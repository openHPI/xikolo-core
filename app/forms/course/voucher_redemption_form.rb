# frozen_string_literal: true

module Course
  class VoucherRedemptionForm < XUI::Form
    self.form_name = 'voucher_redemption'

    attribute :code, :string

    validates :code, presence: true
  end
end
