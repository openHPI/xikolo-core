# frozen_string_literal: true

require 'spec_helper'

describe Account::Email, type: :model do
  describe '.primary' do
    subject(:emails) { described_class.primary }

    before { create(:email) }

    context 'with primary emails' do
      let!(:primary_email) { create(:email, :primary) }

      it 'returns a list of primary emails' do
        expect(emails).to contain_exactly(an_object_having_attributes(
          id: primary_email.id,
          primary: true
        ))
      end
    end

    context 'without primary emails' do
      it 'returns an empty array' do
        expect(emails).to be_empty
      end
    end
  end
end
