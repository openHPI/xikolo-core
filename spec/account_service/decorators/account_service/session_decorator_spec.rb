# frozen_string_literal: true

require 'spec_helper'

describe AccountService::SessionDecorator, type: :decorator do
  let(:session) { create(:'account_service/session') }
  let(:decorator) { described_class.new session }

  describe '#as_json' do
    subject(:payload) { decorator.as_json }

    it 'includes the correct properties' do
      expect(payload.keys).to match_array %w[
        id
        user_id
        user_agent
        masqueraded
        interrupt
        interrupts
        user_url
        self_url
        masquerade_url
        tokens_url
      ]
    end
  end
end
