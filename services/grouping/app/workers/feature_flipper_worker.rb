# frozen_string_literal: true

class FeatureFlipperWorker
  include Sidekiq::Job

  def perform(user_test_id)
    user_test = UserTest.find user_test_id
    # Check if end time changed in the meantime
    return unless user_test.finished?

    user_test.test_groups.each do |test_group|
      next if test_group.invalidated_flipper

      test_group.persist_flippers(nil)
      test_group.update! invalidated_flipper: true
    end
  end
end
