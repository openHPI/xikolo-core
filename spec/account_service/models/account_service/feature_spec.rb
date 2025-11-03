# frozen_string_literal: true

require 'spec_helper'

describe AccountService::Feature, type: :model do
  let(:feature) { create(:'account_service/feature') }
  let(:context) { create(:'account_service/context') }
  let(:groups)  { create_list(:'account_service/group', 4) }
  let(:user)    { create(:'account_service/user') }

  before do
    user.groups << groups[1]
    user.groups << groups[2]
  end

  describe '.lookup' do
    subject { described_class.lookup owner: user, context: }

    context 'with no features' do
      let(:user) { create(:'account_service/user', completed_profile: false) }

      it { is_expected.to match_array [] }
    end

    context 'with user features' do
      let! :features do
        [
          create(:'account_service/feature', owner: user, context:),
          create(:'account_service/feature', owner: user, context: AccountService::Context.root),
        ]
      end

      it { is_expected.to match array_including features }
    end

    context 'with group features' do
      let! :features do
        [
          create(:'account_service/feature', owner: groups[1], context:),
          create(:'account_service/feature', owner: groups[2], context: AccountService::Context.root),
        ]
      end

      it { is_expected.to match array_including features }
    end

    context 'with special group feature' do
      let! :features do
        [
          create(:'account_service/feature', owner: AccountService::Group.all_users, context:),
          create(:'account_service/feature', owner: AccountService::Group.active_users, context: AccountService::Context.root),
        ]
      end

      it { is_expected.to match array_including features }
    end
  end

  describe '.ensure_exists!' do
    let(:kwargs) do
      {
        name: 'feature.test',
        context: AccountService::Context.root,
        owner: user,
      }
    end

    let(:feature) { described_class.ensure_exists!(**kwargs) }

    it 'creates new feature' do
      expect { feature }.to change(AccountService::Feature, :count).by(1)

      expect(feature.name).to eq 'feature.test'
      expect(feature.context).to eq AccountService::Context.root
      expect(feature.owner).to eq user
    end

    it 'default to "true" value' do
      expect(feature.value).to eq 't'
    end

    it 'returns a "new" record' do
      expect(feature.new?).to be true
    end

    context 'with invalid name' do
      let(:kwargs) { super().merge name: '' }

      it 'raises an exception' do
        expect { feature }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on user.feature relation' do
      let(:kwargs) { super().except(:owner) }
      let(:feature) { user.features.ensure_exists!(**kwargs) }

      it 'creates new feature' do
        expect { feature }.to change(described_class, :count).by(1)

        expect(feature.name).to eq 'feature.test'
        expect(feature.context).to eq AccountService::Context.root
        expect(feature.owner).to eq user
      end

      it 'default to "true" value' do
        expect(feature.value).to eq 't'
      end

      it 'returns a "new" record' do
        expect(feature.new?).to be true
      end
    end

    context 'with existing feature' do
      let!(:existing) { described_class.create!(**kwargs, value: 'fuubar') }

      it 'does not create new feature' do
        expect { feature }.not_to change(described_class, :count)
      end

      it 'returns existing feature' do
        expect(feature).to eq existing
      end

      it 'does not update value' do
        expect(feature.value).to eq 'fuubar'
      end

      it 'does not return a "new" record' do
        expect(feature.new?).to be false
      end
    end
  end

  context 'Update' do
    subject(:operation) { described_class::Update.new(owner, context) }

    let(:owner) { user }

    let! :ctx_features do
      create_list(:'account_service/feature', 2, context:, owner:)
    end

    let! :root_features do
      create_list(:'account_service/feature', 2, context: AccountService::Context.root, owner:)
    end

    it 'ignores inherited features' do
      expect do
        operation.call root_features[0].name => 'new_value'
      end.not_to change {
        root_features[0].reload.value
      }
    end

    it 'update features in current context' do
      expect do
        operation.call ctx_features[0].name => 'new_value'
      end.to change {
        ctx_features[0].reload.value
      }.to('new_value')
    end

    it 'add new features to current context' do
      expect do
        operation.call 'abc.def' => 'new_value'
      end.to change {
        described_class.where(owner:, context:).count
      }.from(2).to(3)
    end

    it 'delete features (by setting to nil) in current context' do
      expect do
        operation.call ctx_features[0].name => nil
      end.to change {
        described_class.where(owner:, context:).count
      }.from(2).to(1)
    end

    context 'in different ctx' do
      subject(:operation) { described_class::Update.new(owner, other_context) }

      let(:other_context) { create(:'account_service/context') }

      it 'allows adding features with same name in different contexts' do
        expect do
          operation.call ctx_features[0].name => 'new_value'
        end.to change {
          described_class.where(owner:, name: ctx_features[0].name).count
        }.from(1).to(2)
      end
    end
  end
end
