# frozen_string_literal: true

require 'spec_helper'

describe Session, type: :model do
  subject(:session) { create(:'account_service/session', user:) }

  # User should be created before any spec to avoid catching it's events
  let!(:user) { create(:'account_service/user') }

  describe '#create' do
    it 'publishes event' do
      ActiveRecord::Base.transaction do
        expect(Msgr).to receive(:publish) do |payload, opts|
          expect(opts).to eq to: 'xikolo.account.session.create'

          expect(payload).to eq \
            'id' => session.id,
            'user_id' => session.user.id,
            'user_agent' => nil,
            'masqueraded' => false
        end

        session
      end
    end
  end

  describe '#destroy' do
    subject(:destroy) { session.destroy }

    before { session }

    it 'publishes event' do
      expect(Msgr).to receive(:publish) do |payload, opts|
        expect(opts).to eq to: 'xikolo.account.session.destroy'

        expect(payload).to eq \
          'id' => session.id,
          'user_id' => session.user.id,
          'user_agent' => nil,
          'masqueraded' => false
      end

      destroy
    end
  end
end
