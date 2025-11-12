# frozen_string_literal: true

namespace :migrate_polymorphic_data do
  desc 'Update polymorphic and STI data to include PinboardService namespace'
  task up: :environment do
    PinboardService::Tag.where("type IS NOT NULL AND type != '' " \
                               "AND type NOT LIKE 'PinboardService::%'").find_each do |record|
      record.update_attribute(:type, "PinboardService::#{record.type}") # rubocop:disable Rails/SkipsModelValidations
    end
    PinboardService::Comment.where("commentable_type IS NOT NULL AND commentable_type != '' " \
                                   "AND commentable_type NOT LIKE 'PinboardService::%'").find_each do |record|
      record.update_attribute(:commentable_type, "PinboardService::#{record.commentable_type}") # rubocop:disable Rails/SkipsModelValidations
    end
  end

  task down: :environment do
    PinboardService::Tag.where("type LIKE 'PinboardService::%'").find_each do |record|
      record.update_attribute(:type, record.type.delete_prefix('PinboardService::')) # rubocop:disable Rails/SkipsModelValidations
    end
    PinboardService::Comment.where("commentable_type LIKE 'PinboardService::%'")
      .update_all("commentable_type = REPLACE(commentable_type, 'PinboardService::', '')") # rubocop:disable Rails/SkipsModelValidations
  end
end
