# frozen_string_literal: true

class Consent < ApplicationRecord
  belongs_to :user
  belongs_to :treatment

  after_save_commit do
    if consented?
      begin
        Membership
          .where(user:, group: treatment.group)
          .first_or_create!
      rescue ActiveRecord::RecordNotUnique
        # do nothing
      end
    else
      Membership
        .where(user:, group: treatment.group)
        .destroy_all
    end
  end

  after_destroy do
    Membership
      .where(user:, group: treatment.group)
      .destroy_all
  end

  class << self
    def list
      treatments = Treatment.order(required: :desc, created_at: :asc)
      consents = where(treatment: treatments).group_by(&:treatment_id)

      treatments.map do |t|
        if consents.key?(t.id)
          consents[t.id].first
        else
          new(treatment: t, value: nil)
        end
      end
    end
  end

  def consented?
    value
  end

  alias consented consented?

  def consented_at
    updated_at
  end

  def refused?
    value.equal? false
  end
end
