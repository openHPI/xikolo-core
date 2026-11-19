# frozen_string_literal: true

require 'spec_helper'

describe CurrentUser::User, type: :model do
  subject(:user) { described_class.new(context_id: 'root', session:) }

  describe '#id' do
    let(:session) { create(:'account_service/session') }

    context 'when not masqueraded' do
      it 'returns token users id' do
        expect(user.id).to eq(session.user.id)
      end
    end

    context 'when masqueraded' do
      it 'returns token users id' do
        masqueraded_user = create(:'account_service/user')
        session.masquerade!(masqueraded_user)

        expect(user.id).to eq(masqueraded_user.id)
      end
    end
  end

  describe '#interrupts' do
    let(:session) { instance_double(AccountService::Session, interrupts: %i[foo bar]) }

    it 'returns the sessions interrupts' do
      expect(user.interrupts).to eq(%i[foo bar])
    end
  end

  describe '#anonymous?' do
    let(:session) { instance_double(AccountService::Session) }

    it 'is newer anonymous' do
      expect(user).not_to be_anonymous
    end
  end

  describe '#authenticated?' do
    let(:session) { instance_double(AccountService::Session) }

    it 'is allways authenticated' do
      expect(user).to be_authenticated
    end

    it 'matches logged_in?' do
      expect(user).to be_logged_in
    end
  end

  describe '#masqueraded?' do
    context 'when the session is masqueraded' do
      let(:session) { instance_double(AccountService::Session, masqueraded?: true) }

      it 'is newer masqueraded' do
        expect(user).to be_masqueraded
      end
    end

    context 'when the session is not masqueraded' do
      let(:session) { instance_double(AccountService::Session, masqueraded?: false) }

      it 'matches instrumented?' do
        expect(user).not_to be_instrumented
      end
    end
  end
end
