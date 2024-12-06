# frozen_string_literal: true

##
# Delete all claimant IPs for data privacy reasons after
# one year.
# This job is executed by a cronjob each day.
#
module Voucher
  class DeleteClaimantIPJob < ApplicationJob
    queue_as :default
    queue_with_priority :reporting

    def perform
      # Clear all `claimant_ip` fields where it is not yet cleared
      # and where the voucher has been claimed more than a year ago.
      #
      # age() is a PostgreSQL function that returns the interval between two
      # timestamps.
      # See https://www.postgresql.org/docs/current/functions-datetime.html.
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish
          UPDATE vouchers
          SET claimant_ip = NULL
          WHERE claimant_ip IS NOT NULL
            AND age(now(), claimed_at) > '1 year';
        SQL
      )
    end
  end
end
