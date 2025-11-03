# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Email, type: :model do
  subject(:email) { create(:'account_service/email', attributes) }

  let(:attributes) { {} }

  it do
    expect(email).not_to accept_values_for :address, '',
      'john.smith@exämple.com',
      'john.smith@-example.com',
      'john.smith@example..com',
      'walco.sibbel@example.co@'
  end

  it do
    expect(email).to accept_values_for :address,
      's.yuri@i.ua',
      'john@example.org',
      "o'connor@example.com"
  end

  it 'has case-insensitive unique address' do
    email.update! address: 'John.Smith@example.org'

    expect do
      described_class.create! user: create(:'account_service/user'), address: 'john.Smith@example.org'
    end.to raise_error(/Address has already been taken/)
  end

  describe '#address' do
    subject(:taken) { described_class.address("o'connor@AssassinsCreed.US").take }

    let!(:email) { create(:'account_service/email', address: "O'Connor@assassinscreed.us") }

    it 'searches case-insensitive' do
      expect(taken).to eq email
    end

    context 'with non-existent address' do
      subject { described_class.address('altair@assassinscreed.ar').take }

      it { is_expected.to be_nil }
    end
  end

  describe '#confirmed=' do
    subject(:update) { email.update! confirmed: true }

    let(:attributes) { {confirmed: false} }

    around {|example| Timecop.freeze(&example) }

    it 'sets confirmed_at' do
      expect { update }.to change {
        email.reload.confirmed_at&.to_i
      }.from(nil).to Time.zone.now.to_i
    end

    context 'with unconfirmed user' do
      let(:user) { create(:'account_service/user', :unconfirmed) }
      let(:attributes) { {confirmed: false, confirmed_at: nil, user:} }

      before do
        expect(email.user.reload).not_to be_confirmed
      end

      it 'updates user record' do
        expect { update }.to change {
          email.user.reload.confirmed?
        }.from(false).to(true)
      end

      it 'published confirmed event' do
        allow(Msgr).to receive(:publish)

        expect(Msgr).to receive(:publish).with(anything,
          hash_including(to: 'xikolo.account.user.confirmed'))

        update
      end

      it 'publishes on creation' do
        allow(Msgr).to receive(:publish)

        expect(Msgr).to receive(:publish).with anything,
          hash_including(to: 'xikolo.account.user.create')

        expect(Msgr).to receive(:publish).with anything,
          hash_including(to: 'xikolo.account.user.confirmed')

        create(:'account_service/user')
      end
    end
  end

  describe '#update(primary)' do
    let(:update) { email.update! primary: true }

    let!(:email) do
      create(:'account_service/email', address: "O'Connor@assassinscreed.us")
    end

    let!(:other_email) do
      create(:'account_service/email', user: email.user, address: 'john@example.com', primary: true)
    end

    it 'makes updated email primary' do
      expect { update }.to change { email.reload.primary? }.to(true)
    end

    it 'removed primary flag from previous primary email' do
      expect { update }.to change { other_email.reload.primary? }.to(false)
    end
  end

  describe '#suspend!' do
    subject(:suspend) { email.suspend! }

    let(:user)   { create(:'account_service/user', preferences: {'notification.email.global' => true}) }
    let!(:email) { create(:'account_service/email', address: 'p3k@example.de', user:) }

    it 'adds the feature "primary_email_suspended" for the user' do
      expect { suspend }.to change {
        AccountService::Feature.where(owner: user, name: 'primary_email_suspended').count
      }.from(0).to(1)
    end
  end
end
