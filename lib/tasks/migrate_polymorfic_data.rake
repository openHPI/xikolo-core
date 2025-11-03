# frozen_string_literal: true

namespace :migrate_polymorfic_data do
  desc 'Update plymorfic and STI data to include AccountService namespace'
  task up: :environment do
    AccountService::CustomFieldValue.where("context_type IS NOT NULL AND context_type != '' " \
                                           "AND context_type NOT LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:context_type, "AccountService::#{record.context_type}") # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::Feature.where("owner_type IS NOT NULL AND owner_type != '' " \
                                  "AND owner_type NOT LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:owner_type, "AccountService::#{record.owner_type}") # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::Grant.where("principal_type IS NOT NULL AND principal_type != '' " \
                                "AND principal_type NOT LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:principal_type, "AccountService::#{record.principal_type}") # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::CustomField.unscoped.where("type IS NOT NULL AND type != '' AND type NOT LIKE 'AccountService::%'")
      .find_each do |record|
      record.update_attribute(:type, "AccountService::#{record.type}") # rubocop:disable Rails/SkipsModelValidations
    end
  end

  task down: :environment do
    AccountService::CustomFieldValue.where("context_type LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:context_type, record.context_type.delete_prefix('AccountService::')) # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::Feature.where("owner_type LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:owner_type, record.owner_type.delete_prefix('AccountService::')) # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::Grant.where("principal_type LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:principal_type, record.principal_type.delete_prefix('AccountService::')) # rubocop:disable Rails/SkipsModelValidations
    end

    AccountService::CustomField.unscoped.where("type LIKE 'AccountService::%'").find_each do |record|
      record.update_attribute(:type, record.type.delete_prefix('AccountService::')) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
