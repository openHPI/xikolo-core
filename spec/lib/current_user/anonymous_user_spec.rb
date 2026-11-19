# frozen_string_literal: true

require 'spec_helper'

describe CurrentUser::AnonymousUser, type: :model do
  subject(:anonymous_user) { described_class.new(context_id: 'root') }

  describe '#id' do
    it 'returns anonymous' do
      expect(anonymous_user.id).to eq('anonymous')
    end
  end

  describe '#anonymous?' do
    it 'returns true' do
      expect(anonymous_user).to be_anonymous
    end
  end

  describe '#interrupts' do
    it 'never returns interrupts' do
      expect(anonymous_user.interrupts).to eq([])
    end
  end

  describe '#authenticated?' do
    it 'returns false' do
      expect(anonymous_user).not_to be_authenticated
    end

    it 'matches logged_in?' do
      expect(anonymous_user).not_to be_logged_in
    end
  end

  describe '#masqueraded?' do
    it 'returns false' do
      expect(anonymous_user).not_to be_masqueraded
    end

    it 'matches instrumented?' do
      expect(anonymous_user).not_to be_instrumented
    end
  end

  describe '#user' do
    it 'sets the anonymous_user as user' do
      expect(anonymous_user.send(:user)).to eq(AccountService::User.anonymous)
    end
  end
end
