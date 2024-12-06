# frozen_string_literal: true

require 'spec_helper'

describe EmailDecorator, type: :decorator do
  let(:email) { create(:email, :confirmed) }
  let(:decorator) { described_class.new email }

  describe '#as_json' do
    subject(:json) { decorator.as_json }

    it 'includes the correct properties' do
      expect(json.keys).to match_array %w[
        id
        user_id
        address
        primary
        confirmed
        confirmed_at
        created_at
        user_url
        suspension_url
        self_url
      ]
    end

    it { is_expected.to include 'id' => email.uuid }
    it { is_expected.to include 'user_id' => email.user_id }
    it { is_expected.to include 'address' => email.address }
    it { is_expected.to include 'primary' => email.primary }
    it { is_expected.to include 'confirmed' => email.confirmed }
    it { is_expected.to include 'confirmed_at' => email.confirmed_at.iso8601 }
    it { is_expected.to include 'created_at' => email.created_at.iso8601 }

    it { is_expected.to include 'user_url' => user_url(email.user_id) }
    it { is_expected.to include 'suspension_url' => user_email_suspension_url(email.user_id, email.uuid) }
    it { is_expected.to include 'self_url' => user_email_url(email.user_id, email.uuid) }
  end
end
