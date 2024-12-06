# frozen_string_literal: true

class PopulateUserLastAccess < ActiveRecord::Migration[6.1]
  # Disable blocking the users table (transaction for migration) when
  # backfilling data.
  disable_ddl_transaction!

  class User < ApplicationRecord; end

  class Visit < ApplicationRecord; end

  class Enrollment < ApplicationRecord; end

  def up
    # This populates the last_access attribute of the User model with a reasonable value
    # for those users who haven't visited the platform since the introduction of the
    # attribute in the context of deletion of inactive user accounts.

    User.where(archived: false, confirmed: true, last_access: nil).find_each(batch_size: 500) do |user|
      # Best guess: get the latest item visit and the latest enrollment and take the newest
      visit = Visit.where(user_id: user.id).order(updated_at: :desc).limit(1).take
      enrollment = Enrollment.where(user_id: user.id).order(updated_at: :desc).limit(1).take
      best_guess = [visit&.updated_at, enrollment&.updated_at].compact.max

      if best_guess.present?
        user.update last_access: best_guess
        next
      end

      # Fallback: updated_at timestamp of the actual user, if there is neither
      # a visit nor an enrollment
      user.update last_access: user.updated_at
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
