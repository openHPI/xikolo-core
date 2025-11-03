# frozen_string_literal: true

module AccountService
class Statistics # rubocop:disable Layout/IndentationWidth
  include ActiveModel::Model
  include Statistic

  stat :confirmed_users do
    count User.confirmed
  end

  stat :confirmed_users_last_day do
    count User.confirmed.created_last_day
  end

  stat :confirmed_users_last_7days do
    count User.confirmed.created_last_7days
  end

  stat :unconfirmed_users do
    count User.unconfirmed
  end

  stat :unconfirmed_users_last_day do
    count User.unconfirmed.created_last_day
  end

  stat :users_deleted do
    count User.where(archived: true)
  end

  stat :users_with_suspended_email do
    count Feature.where(owner_type: 'User', name: 'primary_email_suspended')
  end
end
end
