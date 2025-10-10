# frozen_string_literal: true

require 'spec_helper'

describe AuthorizationDecorator, type: :decorator do
  let(:record) { create(:'account_service/authorization') }
  let(:decorator) { described_class.new record }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'includes the correct properties' do
      expect(payload.keys).to match_array %w[
        expires_at
        id
        info
        provider
        secret
        token
        uid
        user_id
      ]
    end

    describe '[expires_at]' do
      subject { payload['expires_at'] }

      it { is_expected.to eq record.expires_at.iso8601 }
    end
  end
end
