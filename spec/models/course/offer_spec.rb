# frozen_string_literal: true

require 'spec_helper'

describe Course::Offer, type: :model do
  describe '(validations)' do
    subject(:offer) { build(:offer) }

    context 'with valid values' do
      it { is_expected.to accept_values_for :price, 100 }
      it { is_expected.to accept_values_for :payment_frequency, 'half_yearly' }
      it { is_expected.to accept_values_for :category, 'certificate' }
      it { is_expected.to accept_values_for :price_currency, 'EUR' }
    end

    context 'with invalid values' do
      it { is_expected.not_to accept_values_for :price, 'a string', -10 }
      it { is_expected.not_to accept_values_for :payment_frequency, 'Half yearly' }
      it { is_expected.not_to accept_values_for :category, 'Certificate' }
      it { is_expected.not_to accept_values_for :price_currency, 'USD' }
    end

    context 'with missing values' do
      it { is_expected.not_to accept_values_for :price, nil }
      it { is_expected.not_to accept_values_for :payment_frequency, nil }
      it { is_expected.not_to accept_values_for :category, nil }
      it { is_expected.not_to accept_values_for :price_currency, nil }
    end
  end
end
