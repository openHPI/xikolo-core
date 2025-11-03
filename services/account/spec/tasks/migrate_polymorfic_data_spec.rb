# frozen_string_literal: true

require 'spec_helper'

Rails.application.load_tasks

RSpec.describe 'user:activate_all' do
  let(:user) { create(:'account_service/user') }
  let!(:custom_field_value) { create(:'account_service/custom_field_value', context: user) }
  let!(:feature) { create(:'account_service/feature', owner: user) }
  let!(:grant) { create(:'account_service/grant', principal: user) }

  before do
    create(:'account_service/custom_select_field', name: 'select')
    create(:'account_service/custom_multi_select_field', name: 'multi_select')
    create(:'account_service/custom_text_field', name: 'text')
  end

  describe ':up' do
    it 'adds prefixes for AccountService' do
      Rake::Task['migrate_polymorfic_data:down'].reenable
      Rake::Task['migrate_polymorfic_data:down'].invoke

      expect do
        Rake::Task['migrate_polymorfic_data:up'].reenable
        Rake::Task['migrate_polymorfic_data:up'].invoke
      end.to change { custom_field_value.reload.context_type }.to('AccountService::User')
        .and change { feature.reload.owner_type }.to('AccountService::User')
        .and change { grant.reload.principal_type }.to('AccountService::User')
        .and change { AccountService::CustomField.unscoped.pluck(:type).sort }
        .to(['AccountService::CustomMultiSelectField', 'AccountService::CustomSelectField', 'AccountService::CustomTextField', 'AccountService::CustomTextField'])
    end
  end

  describe ':down' do
    it 'removes all prefixes' do
      expect do
        Rake::Task['migrate_polymorfic_data:down'].reenable
        Rake::Task['migrate_polymorfic_data:down'].invoke
      end.to change { custom_field_value.reload.context_type }.to('User')
        .and change { feature.reload.owner_type }.to('User')
        .and change { grant.reload.principal_type }.to('User')
        .and change { AccountService::CustomField.unscoped.pluck(:type).sort }
        .to(%w[CustomMultiSelectField CustomSelectField CustomTextField CustomTextField])
    end
  end
end
